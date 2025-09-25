import 'package:flutter/material.dart';

/// Provides simple markdown-style formatting helpers for TextEditingController.
/// - Bold: **text**
/// - Italic: *text*
/// - Strikethrough: ~~text~~
/// - Auto-numbered list: when user presses Enter after a line like `1. `,
///   inserts `2. ` on the new line.
class EditorProvider extends ChangeNotifier {
  void toggleBold(TextEditingController controller) {
    _wrapSelection(controller, prefix: '**', suffix: '**');
  }

  void toggleItalic(TextEditingController controller) {
    _wrapSelection(controller, prefix: '*', suffix: '*');
  }

  void toggleStrikethrough(TextEditingController controller) {
    _wrapSelection(controller, prefix: '~~', suffix: '~~');
  }

  /// Call this inside a text change listener. If the last change introduced
  /// a newline and the previous line is a list item (numbered or bulleted),
  /// auto-continues the list on the new line.
  void handleAutoNumberedList(
    TextEditingController controller, {
    required String previousText,
  }) {
    final currentText = controller.text;
    // Only proceed if one more newline exists than before.
    if (currentText.length < previousText.length) return;
    final added = currentText.substring(previousText.length);
    if (!added.contains('\n')) return;

    final selection = controller.selection;
    final cursor = selection.start;
    final textUntilCursor = currentText.substring(0, cursor);

    // Find the line immediately before the cursor (excluding the just-added newline)
    final lines = textUntilCursor.split('\n');
    if (lines.length < 2) return;
    final prevLine = lines[lines.length - 2];

    // Numbered list like `1. `
    final numMatch = RegExp(r'^(\d+)\.\s').firstMatch(prevLine);
    String insertText;
    if (numMatch != null) {
      final prevNumber = int.tryParse(numMatch.group(1) ?? '');
      if (prevNumber == null) return;
      insertText = '${prevNumber + 1}. ';
    } else if (RegExp(r'^(\-|\*)\s').hasMatch(prevLine)) {
      // Bulleted list like `- ` or `* `
      insertText = '- ';
    } else {
      return;
    }

    // Insert at cursor position (start and end are the same right after newline)
    final newText = currentText.replaceRange(cursor, cursor, insertText);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
      composing: TextRange.empty,
    );
    notifyListeners();
  }

  void _wrapSelection(
    TextEditingController controller, {
    required String prefix,
    required String suffix,
  }) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0) return;

    // If no selection, wrap a placeholder word.
    if (start == end) {
      final insert = '$prefix$suffix';
      final newText = text.replaceRange(start, end, insert);
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
        composing: TextRange.empty,
      );
      notifyListeners();
      return;
    }

    final selected = text.substring(start, end);
    final newSelected = '$prefix$selected$suffix';
    final newText = text.replaceRange(start, end, newSelected);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + newSelected.length,
      ),
      composing: TextRange.empty,
    );
    notifyListeners();
  }

  /// Insert or toggle bullet prefix (`- `) at the start of the current line(s).
  void toggleBulletedList(TextEditingController controller) {
    _toggleLinePrefix(controller, '- ');
  }

  /// Insert or toggle numbered prefix (`1. `) starting at 1 for the current line(s).
  void toggleNumberedList(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0) return;

    final lines = _selectedLines(text, start, end);
    int number = 1;
    final edits = <_LineEdit>[];
    for (final line in lines) {
      final lineText = text.substring(line.start, line.end);
      final hasNumber = RegExp(r'^(\d+)\.\s').hasMatch(lineText);
      final hasBullet = RegExp(r'^(\-|\*)\s').hasMatch(lineText);
      if (hasNumber) {
        // Remove number
        final m = RegExp(r'^(\d+)\.\s').firstMatch(lineText)!;
        edits.add(_LineEdit(line.start, line.start + m.group(0)!.length, ''));
      } else if (hasBullet) {
        // Replace bullet with proper number
        final m = RegExp(r'^(\-|\*)\s').firstMatch(lineText)!;
        edits.add(_LineEdit(line.start, line.start + m.group(0)!.length, '${number++}. '));
      } else {
        edits.add(_LineEdit(line.start, line.start, '${number++}. '));
      }
    }
    _applyLineEdits(controller, edits);
  }

  void _toggleLinePrefix(TextEditingController controller, String prefix) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    if (start < 0 || end < 0) return;

    final lines = _selectedLines(text, start, end);
    final edits = <_LineEdit>[];
    for (final line in lines) {
      final lineText = text.substring(line.start, line.end);
      final hasPrefix = lineText.startsWith(prefix) ||
          (prefix == '- ' && RegExp(r'^(\-|\*)\s').hasMatch(lineText));
      if (hasPrefix) {
        // remove
        final removeLen = RegExp(r'^(\d+\.\s)|(\-|\*)\s')
                .firstMatch(lineText)
                ?.group(0)
                ?.length ??
            prefix.length;
        edits.add(_LineEdit(line.start, line.start + removeLen, ''));
      } else {
        edits.add(_LineEdit(line.start, line.start, prefix));
      }
    }
    _applyLineEdits(controller, edits);
  }

  List<_LineRange> _selectedLines(String text, int start, int end) {
    int s = start;
    int e = end;
    // expand to full lines
    while (s > 0 && text[s - 1] != '\n') s--;
    while (e < text.length && text[e] != '\n') e++;
    final segment = text.substring(s, e);
    final lines = <_LineRange>[];
    int offset = s;
    for (final part in segment.split('\n')) {
      lines.add(_LineRange(offset, offset + part.length));
      offset += part.length + 1; // include newline
    }
    return lines;
  }

  void _applyLineEdits(TextEditingController controller, List<_LineEdit> edits) {
    if (edits.isEmpty) return;
    edits.sort((a, b) => b.start.compareTo(a.start)); // apply backwards
    String t = controller.text;
    for (final e in edits) {
      t = t.replaceRange(e.start, e.end, e.insert);
    }
    final selStart = edits.last.start + edits.last.insert.length;
    controller.value = controller.value.copyWith(
      text: t,
      selection: TextSelection.collapsed(offset: selStart),
      composing: TextRange.empty,
    );
    notifyListeners();
  }
}

class _LineRange {
  final int start;
  final int end;
  _LineRange(this.start, this.end);
}

class _LineEdit {
  final int start;
  final int end;
  final String insert;
  _LineEdit(this.start, this.end, this.insert);
}
