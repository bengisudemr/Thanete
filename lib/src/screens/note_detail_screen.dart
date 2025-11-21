import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:thanette/src/models/note.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/widgets/drawing_toolbar.dart';
import 'package:thanette/src/widgets/drawing_canvas.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/widgets/todo_list_widget.dart';
import 'package:thanette/src/widgets/floating_chat_bubble.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/services/annotation_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thanette/src/screens/enhanced_file_annotation_screen.dart';

class NoteDetailArgs {
  final String? id;
  const NoteDetailArgs({this.id});
}

class NoteDetailScreen extends StatefulWidget {
  static const route = '/note';
  final NoteDetailArgs args;
  const NoteDetailScreen({super.key, required this.args});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  final ScrollController _bodyScrollController = ScrollController();
  bool _hasChanges = false;
  bool _isKeyboardVisible = false;
  bool _isDrawingMode = false;
  bool _justSaved = false;
  String? _currentNoteId;
  late quill.QuillController _quillController;
  DrawingSettings _drawingSettings = DrawingSettings();
  DrawingData _drawingData = DrawingData(paths: [], canvasSize: Size.zero);
  bool _isModalOpen =
      false; // controls FloatingChatBubble visibility when modals are shown
  bool _isInFileAnnotation =
      false; // controls FloatingChatBubble visibility in file annotation
  double _savedScrollOffset =
      0.0; // Remember scroll position when entering drawing mode
  double _currentScrollOffset =
      0.0; // Track live scroll offset for drawing alignment

  // Drawing undo/redo history
  List<DrawingData> _drawingHistory = [];
  int _drawingHistoryIndex = -1;

  // Note edit history for persistent undo/redo
  List<Map<String, dynamic>> _noteHistory =
      []; // List of {title, body} snapshots
  int _noteHistoryIndex = -1; // Current position in history
  static const int _maxHistorySize = 50; // Limit history size

  // Todo list state
  List<TodoItem> _todos = [];

  // Formatting state
  bool _isBoldActive = false;
  bool _isItalicActive = false;
  bool _isUnderlineActive = false;
  bool _isBulletListActive = false;
  bool _isNumberedListActive = false;
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    final note = widget.args.id != null
        ? context.read<NotesProvider>().getById(widget.args.id!)
        : null;
    _currentNoteId = widget.args.id;
    _titleController = TextEditingController(text: note?.title ?? '');
    _bodyController = TextEditingController(text: note?.body ?? '');
    _selectedCategory = note?.category ?? 'general';

    // Listen to title changes to update header and auto-save
    _titleController.addListener(() {
      setState(() {});
      _onContentChanged();
    });

    // Initialize quill with existing content
    quill.Document document;
    if (note?.body != null && note!.body.isNotEmpty) {
      try {
        // Try to parse as Quill Delta JSON
        final deltaJson = note.body;
        final parsedJson = jsonDecode(deltaJson);
        document = quill.Document.fromJson(parsedJson);
      } catch (e) {
        // If parsing fails, treat as plain text
        document = quill.Document()..insert(0, note.body);
      }
    } else {
      document = quill.Document();
    }

    _quillController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Load existing drawing data
    _loadDrawingData(note);

    // Load existing todos
    if (note?.todos != null) {
      _todos = List.from(note!.todos);
    }

    // Initialize drawing history with current drawing data
    _addToDrawingHistory(_drawingData);

    // Load note history from SharedPreferences
    _loadNoteHistory();

    // Add listener for checklist clicks and content changes
    _quillController.addListener(_onQuillSelectionChanged);
    _quillController.addListener(_onQuillContentChanged);

    // Add listener for keyboard done button
    _bodyFocusNode.addListener(_onBodyFocusChanged);
    _bodyScrollController.addListener(_handleBodyScroll);

    // Listen to keyboard visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
    });
  }

  void _updateKeyboardVisibility() {
    final mediaQuery = MediaQuery.of(context);
    final newKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    if (newKeyboardVisible != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = newKeyboardVisible;
      });
      // Don't auto-scroll on keyboard appearance - let Flutter handle it naturally
    }
  }

  void _onQuillSelectionChanged() {
    final selection = _quillController.selection;

    // Reset formatting states when selection changes
    // (User can click on formatted text, we'll update on next format action)

    if (selection.isCollapsed) {
      final offset = selection.baseOffset;
      final document = _quillController.document;

      // Guard against invalid offsets when document is empty
      if (!selection.isValid || offset <= 0) {
        return;
      }

      final docLength = document.length;
      if (offset > docLength) {
        return;
      }

      if (offset > 0) {
        final prevChar = document.getPlainText(offset - 1, offset);
        if (prevChar == '☐' || prevChar == '☑') {
          _toggleChecklistItem(offset - 1);
        }
      }
    }
  }

  void _onQuillContentChanged() {
    _onContentChanged();

    // Don't auto-scroll - let user control scroll position manually
    // This prevents unwanted scrolling when typing
  }

  void _handleDoubleTap(Offset globalPosition) {
    if (_isDrawingMode) return;
    
    // Request focus first
    _bodyFocusNode.requestFocus();
    
    // Convert global position to local position relative to QuillEditor
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(globalPosition);
    
    // Get the scroll offset
    final scrollOffset = _bodyScrollController.hasClients 
        ? _bodyScrollController.offset 
        : 0.0;
    
    // Adjust local position by scroll offset
    final adjustedPosition = Offset(
      localPosition.dx,
      localPosition.dy + scrollOffset,
    );
    
    // Try to find the closest text position
    // Since QuillEditor doesn't expose getOffsetForPosition directly,
    // we'll estimate based on line height and document structure
    final document = _quillController.document;
    final documentLength = document.length;
    
    if (documentLength == 0) {
      // Empty document, place cursor at start
      _quillController.updateSelection(
        const TextSelection.collapsed(offset: 0),
        quill.ChangeSource.local,
      );
      return;
    }
    
    // Estimate line height (approximate)
    const double estimatedLineHeight = 24.0;
    const double estimatedPadding = 16.0;
    
    // Calculate which line we're on (rough estimate)
    final lineIndex = ((adjustedPosition.dy - estimatedPadding) / estimatedLineHeight).floor().clamp(0, 1000);
    
    // Get plain text to estimate character position
    final plainText = document.toPlainText();
    final lines = plainText.split('\n');
    
    int estimatedOffset = 0;
    for (int i = 0; i < lineIndex && i < lines.length; i++) {
      estimatedOffset += lines[i].length + 1; // +1 for newline
    }
    
    // Clamp to document length
    estimatedOffset = estimatedOffset.clamp(0, documentLength - 1);
    
    // Place cursor at estimated position
    _quillController.updateSelection(
      TextSelection.collapsed(offset: estimatedOffset),
      quill.ChangeSource.local,
    );
  }

  void _toggleChecklistItem(int offset) {
    final document = _quillController.document;
    final char = document.getPlainText(offset, offset + 1);
    final newChar = char == '☐' ? '☑' : '☐';

    _quillController.replaceText(offset, 1, newChar, null);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: offset + 1),
      quill.ChangeSource.local,
    );
  }

  void _onBodyFocusChanged() {
    _updateKeyboardVisibility();
    // Don't auto-scroll on focus - preserve user's scroll position
  }

  // ignore: unused_element
  void _scrollToBottom() {
    if (_bodyScrollController.hasClients &&
        _bodyScrollController.position.maxScrollExtent > 0) {
      _bodyScrollController.animateTo(
        _bodyScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleBodyScroll() {
    if (!_bodyScrollController.hasClients) return;

    final offset = _bodyScrollController.offset;
    if ((offset - _currentScrollOffset).abs() < 0.1) {
      return;
    }

    if (_isDrawingMode) {
      setState(() {
        _currentScrollOffset = offset;
      });
    } else {
      _currentScrollOffset = offset;
    }
  }

  bool _hasListLikeMarkers(String text) {
    // Detect bullets: -, *, • and numbered lists: 1. 2.
    final bulletOrNumbered = RegExp(r'^\s*(?:[-*•]|\d+\.)\s+', multiLine: true);
    return bulletOrNumbered.hasMatch(text);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _historyTimer?.cancel();

    // Remove listeners before disposing
    _bodyFocusNode.removeListener(_onBodyFocusChanged);
    _quillController.removeListener(_onQuillSelectionChanged);
    _quillController.removeListener(_onQuillContentChanged);

    // Unfocus before disposing to prevent keyboard state issues
    _titleFocusNode.unfocus();
    _bodyFocusNode.unfocus();

    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _bodyScrollController.removeListener(_handleBodyScroll);
    _bodyScrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Timer? _saveTimer;
  Timer? _historyTimer; // Debounce history saves
  bool _isSaving = false;
  bool _noteCreated = false;

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }

    // Debounce history saves - save after 1 second of no changes
    // This prevents saving on every keystroke
    _historyTimer?.cancel();
    _historyTimer = Timer(const Duration(milliseconds: 1000), () {
      _addToNoteHistory();
    });

    // Debounce auto-save - save after 0.5 seconds of no changes
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _autoSave();
    });
  }

  Future<void> _loadNoteHistory() async {
    // Wait for controllers to be initialized
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (_currentNoteId != null) {
        // Load existing history for saved note
        final prefs = await SharedPreferences.getInstance();
        final historyKey = 'note_history_$_currentNoteId';
        final historyJson = prefs.getString(historyKey);

        if (historyJson != null) {
          final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
          _noteHistory = List<Map<String, dynamic>>.from(
            (decoded['history'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          );
          _noteHistoryIndex =
              decoded['index'] as int? ?? _noteHistory.length - 1;

          // Ensure history index is valid
          if (_noteHistoryIndex < 0 ||
              _noteHistoryIndex >= _noteHistory.length) {
            _noteHistoryIndex = _noteHistory.length > 0
                ? _noteHistory.length - 1
                : -1;
          }
          return;
        }
      }

      // Initialize with current state (for new notes or when no history exists)
      _noteHistory = [
        {
          'title': _titleController.text,
          'body': jsonEncode(_quillController.document.toDelta().toJson()),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];
      _noteHistoryIndex = 0;

      // Save if note already has an ID
      if (_currentNoteId != null) {
        await _saveNoteHistory();
      }
    } catch (e) {
      print('Error loading note history: $e');
      // Initialize with current state on error
      _noteHistory = [
        {
          'title': _titleController.text,
          'body': jsonEncode(_quillController.document.toDelta().toJson()),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];
      _noteHistoryIndex = 0;
    }
  }

  Future<void> _saveNoteHistory() async {
    if (_currentNoteId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'note_history_$_currentNoteId';
      final historyData = {'history': _noteHistory, 'index': _noteHistoryIndex};
      await prefs.setString(historyKey, jsonEncode(historyData));
    } catch (e) {
      print('Error saving note history: $e');
    }
  }

  void _addToNoteHistory() {
    // Skip if in drawing mode (drawing has its own history)
    if (_isDrawingMode) return;

    final currentTitle = _titleController.text;
    final currentBody = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    // Don't add if same as current history entry
    if (_noteHistory.isNotEmpty &&
        _noteHistoryIndex >= 0 &&
        _noteHistoryIndex < _noteHistory.length) {
      final lastEntry = _noteHistory[_noteHistoryIndex];
      if (lastEntry['title'] == currentTitle &&
          lastEntry['body'] == currentBody) {
        return; // No change, skip adding
      }
    }

    // Remove any history after current index
    if (_noteHistoryIndex < _noteHistory.length - 1) {
      _noteHistory = _noteHistory.sublist(0, _noteHistoryIndex + 1);
    }

    // Add new entry
    _noteHistory.add({
      'title': currentTitle,
      'body': currentBody,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Limit history size
    if (_noteHistory.length > _maxHistorySize) {
      _noteHistory.removeAt(0);
    } else {
      _noteHistoryIndex++;
    }

    // Save to SharedPreferences asynchronously (don't await to avoid blocking)
    _saveNoteHistory();
  }

  void _onDrawingChanged() {
    _onContentChanged(); // Trigger auto-save when drawing changes
    // Add to history when drawing is completed
    _addToDrawingHistory(_drawingData);
  }

  void _addToDrawingHistory(DrawingData drawingData) {
    // Remove any history after current index
    if (_drawingHistoryIndex < _drawingHistory.length - 1) {
      _drawingHistory = _drawingHistory.sublist(0, _drawingHistoryIndex + 1);
    }

    // Add new state to history
    _drawingHistory.add(
      DrawingData(
        paths: List.from(drawingData.paths),
        canvasSize: drawingData.canvasSize,
      ),
    );

    // Limit history size
    if (_drawingHistory.length > 20) {
      _drawingHistory.removeAt(0);
    } else {
      _drawingHistoryIndex++;
    }
  }

  void _undoDrawing() {
    if (_drawingHistoryIndex > 0) {
      _drawingHistoryIndex--;
      setState(() {
        _drawingData = DrawingData(
          paths: List.from(_drawingHistory[_drawingHistoryIndex].paths),
          canvasSize: _drawingHistory[_drawingHistoryIndex].canvasSize,
        );
      });
    }
  }

  void _redoDrawing() {
    if (_drawingHistoryIndex < _drawingHistory.length - 1) {
      _drawingHistoryIndex++;
      setState(() {
        _drawingData = DrawingData(
          paths: List.from(_drawingHistory[_drawingHistoryIndex].paths),
          canvasSize: _drawingHistory[_drawingHistoryIndex].canvasSize,
        );
      });
    }
  }

  bool _canUndoNote() {
    return _noteHistoryIndex > 0;
  }

  bool _canRedoNote() {
    return _noteHistoryIndex < _noteHistory.length - 1;
  }

  Future<void> _undoNote() async {
    if (!_canUndoNote()) return;

    try {
      // Cancel any pending history saves to avoid duplicate entries
      _historyTimer?.cancel();

      // Move back in history
      _noteHistoryIndex--;
      final historyEntry = _noteHistory[_noteHistoryIndex];

      // Temporarily disable content change listener to avoid adding to history
      _quillController.removeListener(_onQuillContentChanged);

      // Restore title and body
      _titleController.text = historyEntry['title'] as String? ?? '';

      try {
        final bodyJson = jsonDecode(historyEntry['body'] as String);
        final document = quill.Document.fromJson(bodyJson);
        _quillController.document = document;
        _quillController.updateSelection(
          const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.local,
        );
      } catch (e) {
        print('Error restoring body from history: $e');
      }

      // Re-enable listener
      _quillController.addListener(_onQuillContentChanged);

      setState(() {
        _hasChanges = true;
      });

      // Save updated history
      await _saveNoteHistory();

      // Manually trigger save without adding to history
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        _autoSave();
      });
    } catch (e) {
      print('Error in undo: $e');
    }
  }

  Future<void> _redoNote() async {
    if (!_canRedoNote()) return;

    try {
      // Cancel any pending history saves to avoid duplicate entries
      _historyTimer?.cancel();

      // Move forward in history
      _noteHistoryIndex++;
      final historyEntry = _noteHistory[_noteHistoryIndex];

      // Temporarily disable content change listener to avoid adding to history
      _quillController.removeListener(_onQuillContentChanged);

      // Restore title and body
      _titleController.text = historyEntry['title'] as String? ?? '';

      try {
        final bodyJson = jsonDecode(historyEntry['body'] as String);
        final document = quill.Document.fromJson(bodyJson);
        _quillController.document = document;
        _quillController.updateSelection(
          const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.local,
        );
      } catch (e) {
        print('Error restoring body from history: $e');
      }

      // Re-enable listener
      _quillController.addListener(_onQuillContentChanged);

      setState(() {
        _hasChanges = true;
      });

      // Save updated history
      await _saveNoteHistory();

      // Manually trigger save without adding to history
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        _autoSave();
      });
    } catch (e) {
      print('Error in redo: $e');
    }
  }

  Future<void> _autoSave() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true; // trigger UI to show saving chip immediately
    });
    try {
      final notesProvider = context.read<NotesProvider>();
      final title = _titleController.text.trim();
      final body = jsonEncode(_quillController.document.toDelta().toJson());

      if (_currentNoteId != null) {
        // Update existing note with drawing data
        await notesProvider.updateNoteRemote(
          id: _currentNoteId!,
          title: title,
          body: body,
          category: _selectedCategory,
        );
        // Always save drawing data (even if empty - for erasing)
        print('Saving drawing data with ${_drawingData.paths.length} paths');
        await notesProvider.updateNoteDrawing(_currentNoteId!, _drawingData);
        print('Drawing data saved successfully');
        // Save todos
        await notesProvider.updateNoteTodos(_currentNoteId!, _todos);
      } else if (!_noteCreated) {
        setState(() {
          _isDrawingMode = true;
        });

        final newNoteId = await notesProvider.createNoteRemote(
          title: title,
          body: body,
        );
        _noteCreated = true;
        _currentNoteId = newNoteId;
        _loadNoteHistory();

        setState(() {
          _isDrawingMode = false;
        });

        print(
          'Saving drawing data for new note with ${_drawingData.paths.length} paths',
        );
        await notesProvider.updateNoteDrawing(newNoteId, _drawingData);
        print('Drawing data saved for new note successfully');
        await notesProvider.updateNoteTodos(newNoteId, _todos);
      }

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _justSaved = true; // show "saved" state
        });
        // Auto-hide the saved state shortly after, if not saving again
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          if (!_isSaving) {
            setState(() {
              _justSaved = false;
            });
          }
        });
      }
    } catch (e) {
      // Silent fail for auto-save - don't show error to user
      print('Auto-save failed: $e');
    } finally {
      _isSaving = false;
      if (mounted) {
        setState(() {
          _isDrawingMode = false;
        });
      }
    }
  }

  void _toggleDrawingMode() {
    _showDrawingPropertiesMenu();
  }

  Future<T?> _showCupertinoSheet<T>({
    required Widget child,
    bool dismissible = true,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (ctx) =>
          CupertinoPopupSurface(child: SafeArea(top: false, child: child)),
    );
  }

  void _showDrawingPropertiesMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Çizim seçenekleri'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _activateDrawingMode();
            },
            child: const Text('Çizim Modu'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showFileAnnotationOptions();
            },
            child: const Text('Dosya Notlama'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _activateDrawingMode() {
    try {
      // Save current scroll position before toggling - safely check
      if (_bodyScrollController.hasClients) {
        _savedScrollOffset = _bodyScrollController.offset;
      } else {
        // If controller not ready, use saved offset or default
        _savedScrollOffset = _savedScrollOffset;
      }

      final currentOffset = _bodyScrollController.hasClients
          ? _bodyScrollController.offset
          : _currentScrollOffset;

      setState(() {
        _currentScrollOffset = currentOffset;
        _isDrawingMode = !_isDrawingMode;
        _quillController.readOnly = _isDrawingMode;
      });

      if (_isDrawingMode) {
        // Unfocus to prevent keyboard from opening and disrupting scroll
        FocusScope.of(context).unfocus();
        // Restore scroll position after a brief delay to ensure layout is stable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              try {
                if (_bodyScrollController.hasClients &&
                    _savedScrollOffset >= 0) {
                  _bodyScrollController.jumpTo(_savedScrollOffset);
                }
                Future.delayed(const Duration(milliseconds: 120), () {
                  if (mounted && _bodyScrollController.hasClients) {
                    _bodyScrollController.animateTo(
                      _bodyScrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              } catch (e) {
                print('Error restoring scroll position: $e');
                // Ignore scroll errors - not critical
              }
            }
          });
        });
      } else {
        // Save drawings when exiting drawing mode
        _saveDrawings();
      }
    } catch (e) {
      print('Error in _activateDrawingMode: $e');
      // Still toggle drawing mode even if scroll fails
      setState(() {
        _isDrawingMode = !_isDrawingMode;
        _quillController.readOnly = _isDrawingMode;
      });
    }
  }

  void _loadDrawingData(note) {
    if (note?.drawingData != null && note!.drawingData.isNotEmpty) {
      try {
        // drawingData is already a DrawingData object, not a string
        _drawingData = note.drawingData!;
        print('Loaded drawing data with ${_drawingData.paths.length} paths');
      } catch (e) {
        print('Error loading drawing data: $e');
        // If parsing fails, keep empty drawing data
        _drawingData = DrawingData(paths: [], canvasSize: Size.zero);
      }
    } else {
      print('No drawing data found for note');
    }
  }

  void _saveDrawings() async {
    if (_drawingData.paths.isEmpty) return;

    try {
      final notesProvider = context.read<NotesProvider>();

      if (widget.args.id != null) {
        // Update existing note with drawing data
        await notesProvider.updateNoteDrawing(widget.args.id!, _drawingData);
      } else {
        // For new notes, save will be handled by auto-save
        _onContentChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çizim kaydetme hatası: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showExistingFiles() async {
    try {
      final files = _currentNoteId == null
          ? <NoteFile>[]
          : await AnnotationService().getNoteFiles(_currentNoteId!);

      final providerNote = _currentNoteId != null
          ? context.read<NotesProvider>().getById(_currentNoteId!)
          : null;
      final providerAttachments = providerNote?.attachments ?? [];

      if (mounted) {
        setState(() {
          _isModalOpen = true;
        });

        _showCupertinoSheet(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Mevcut Dosyalar',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: AppTheme.fontWeightBold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Kapat',
                          style: TextStyle(color: AppTheme.primaryPink),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingM),

                if (files.isEmpty && providerAttachments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXXL,
                      vertical: AppTheme.spacingXXL,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.folder_badge_plus,
                          size: 42,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text(
                          _currentNoteId == null
                              ? 'Notu kaydedip dosya ekleyebilirsiniz.'
                              : 'Henüz dosya yüklenmemiş.',
                          textAlign: TextAlign.center,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        CupertinoButton.filled(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showImageOptions();
                          },
                          child: const Text('Dosya Ekle'),
                        ),
                      ],
                    ),
                  )
                else if (files.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXXL,
                        vertical: AppTheme.spacingM,
                      ),
                      itemCount: files.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacingM),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return _buildFileTile(file);
                      },
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXXL,
                        vertical: AppTheme.spacingM,
                      ),
                      itemCount: providerAttachments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacingM),
                      itemBuilder: (context, index) {
                        final attachment = providerAttachments[index];
                        return _buildAttachmentPreviewTile(attachment);
                      },
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ).whenComplete(() {
          if (mounted) {
            setState(() {
              _isModalOpen = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosyalar yüklenemedi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Widget _buildAttachmentPreviewTile(NoteAttachment attachment) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () async {
          try {
            final uri = Uri.parse(attachment.path);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dosya açılamadı: $e'),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              );
            }
          }
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                attachment.type == AttachmentType.image
                    ? Icons.image
                    : Icons.insert_drive_file,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                  ),
                  Text(
                    attachment.displaySize,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                try {
                  if (await canLaunchUrl(Uri.parse(attachment.path))) {
                    await launchUrl(
                      Uri.parse(attachment.path),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dosya açılamadı: $e'),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Icon(Icons.open_in_new, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
            child: const Text('Notu Sil'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _shareNote();
                }
              });
            },
            child: const Text('Paylaş'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement copy functionality
            },
            child: const Text('Kopyala'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _shareNote() async {
    if (!mounted) return;

    final title = _titleController.text.trim();
    final bodyText = _quillController.document.toPlainText();

    // Build share text
    String shareText = '';
    if (title.isNotEmpty) {
      shareText = '$title\n\n';
    }
    if (bodyText.isNotEmpty) {
      shareText += bodyText;
    }

    // If both are empty, show a message
    if (shareText.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paylaşılacak içerik bulunamadı'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    _showShareSheet(shareText, title);
  }

  void _showShareSheet(String shareText, String title) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Paylaş'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _shareViaEmail(shareText, title);
                }
              });
            },
            child: const Text('E-posta ile Paylaş'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _shareViaWhatsApp(shareText);
                }
              });
            },
            child: const Text('WhatsApp ile Paylaş'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _shareViaEmail(String text, String title) async {
    try {
      // Build mailto URL using Uri constructor (more reliable on iOS)
      final emailUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': title.isNotEmpty ? title : 'Not',
          'body': text,
        },
      );

      print('Attempting to launch email URI: $emailUri');

      // Try to launch email app - use platformDefault first (works better on iOS)
      bool launched = false;
      try {
        launched = await launchUrl(emailUri, mode: LaunchMode.platformDefault);
        print('PlatformDefault launch result: $launched');
      } catch (e1) {
        print('PlatformDefault mode failed: $e1');

        // Fallback: try externalApplication mode
        try {
          launched = await launchUrl(
            emailUri,
            mode: LaunchMode.externalApplication,
          );
          print('ExternalApplication launch result: $launched');
        } catch (e2) {
          print('ExternalApplication mode failed: $e2');
        }
      }

      if (launched) {
        // Success - email app opened
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('E-posta uygulaması açıldı'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      } else {
        // If URL launch failed, use share sheet as fallback
        print('mailto: launch failed, using share sheet');
        await Share.share(text, subject: title.isNotEmpty ? title : 'Not');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Paylaşım menüsünden e-posta uygulamasını seçebilirsiniz',
              ),
              backgroundColor: AppTheme.info,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Email share error: $e');

      // Final fallback: share sheet
      try {
        await Share.share(text, subject: title.isNotEmpty ? title : 'Not');
      } catch (shareError) {
        print('Share sheet also failed: $shareError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta açılamadı: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _shareViaWhatsApp(String text) async {
    try {
      // Encode text for WhatsApp URL
      final encodedText = Uri.encodeComponent(text);

      Uri whatsappUri;
      if (Platform.isIOS) {
        // iOS: Try whatsapp:// scheme first
        whatsappUri = Uri.parse('whatsapp://send?text=$encodedText');
      } else {
        // Android: Use web version
        whatsappUri = Uri.parse('https://wa.me/?text=$encodedText');
      }

      // Try to launch WhatsApp directly - don't rely on canLaunchUrl
      try {
        final launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WhatsApp açılıyor...'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        } else {
          // If launch failed, try web version (iOS fallback)
          if (Platform.isIOS) {
            final webUri = Uri.parse('https://wa.me/?text=$encodedText');
            try {
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
            } catch (webError) {
              // Final fallback: use share sheet
              await Share.share(text);
            }
          } else {
            // Android: use share sheet as fallback
            await Share.share(text);
          }
        }
      } catch (launchError) {
        print(
          'WhatsApp direct launch failed: $launchError, trying alternatives',
        );

        // Try web version if direct launch failed
        if (Platform.isIOS) {
          try {
            final webUri = Uri.parse('https://wa.me/?text=$encodedText');
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          } catch (webError) {
            // Final fallback: use share sheet
            await Share.share(text);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Paylaşım menüsünden WhatsApp\'ı seçebilirsiniz',
                  ),
                  backgroundColor: AppTheme.info,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              );
            }
          }
        } else {
          // Android fallback
          await Share.share(text);
        }
      }
    } catch (e) {
      print('WhatsApp share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp açılamadı: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Notu Sil'),
        content: const Text(
          'Bu notu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteNote();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (widget.args.id == null) {
      Navigator.pop(context);
      return;
    }

    try {
      final notesProvider = context.read<NotesProvider>();
      await notesProvider.deleteNoteRemote(widget.args.id!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Not silindi'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showFileAnnotationOptions() async {
    try {
      if (_currentNoteId == null) return;
      final files = await AnnotationService().getNoteFiles(_currentNoteId!);

      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Henüz dosya yüklenmemiş'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isInFileAnnotation = true;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'enhanced_file_annotation'),
            builder: (context) =>
                EnhancedFileAnnotationScreen(file: files.first),
          ),
        ).then((_) {
          setState(() {
            _isInFileAnnotation = false;
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya listesi yüklenirken hata: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showTextFormattingMenu() {
    _showCupertinoSheet(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFormatButton(
                    icon: Icons.format_bold,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isBoldActive) {
                          _quillController.formatSelection(
                            quill.Attribute.clone(quill.Attribute.bold, null),
                          );
                          _isBoldActive = false;
                        } else {
                          _quillController.formatSelection(
                            quill.Attribute.bold,
                          );
                          _isBoldActive = true;
                        }
                      });
                    },
                    isActive: _isBoldActive,
                  ),
                  _buildFormatButton(
                    icon: Icons.format_italic,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isItalicActive) {
                          _quillController.formatSelection(
                            quill.Attribute.clone(quill.Attribute.italic, null),
                          );
                          _isItalicActive = false;
                        } else {
                          _quillController.formatSelection(
                            quill.Attribute.italic,
                          );
                          _isItalicActive = true;
                        }
                      });
                    },
                    isActive: _isItalicActive,
                  ),
                  _buildFormatButton(
                    icon: Icons.format_underlined,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isUnderlineActive) {
                          _quillController.formatSelection(
                            quill.Attribute.clone(
                              quill.Attribute.underline,
                              null,
                            ),
                          );
                          _isUnderlineActive = false;
                        } else {
                          _quillController.formatSelection(
                            quill.Attribute.underline,
                          );
                          _isUnderlineActive = true;
                        }
                      });
                    },
                    isActive: _isUnderlineActive,
                  ),
                  _buildFormatButton(
                    icon: Icons.format_list_bulleted,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isBulletListActive) {
                          _quillController.formatSelection(
                            quill.Attribute.clone(quill.Attribute.ul, null),
                          );
                          _isBulletListActive = false;
                        } else {
                          _quillController.formatSelection(quill.Attribute.ul);
                          _isBulletListActive = true;
                        }
                      });
                    },
                    isActive: _isBulletListActive,
                  ),
                  _buildFormatButton(
                    icon: Icons.format_list_numbered,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isNumberedListActive) {
                          _quillController.formatSelection(
                            quill.Attribute.clone(quill.Attribute.ol, null),
                          );
                          _isNumberedListActive = false;
                        } else {
                          _quillController.formatSelection(quill.Attribute.ol);
                          _isNumberedListActive = true;
                        }
                      });
                    },
                    isActive: _isNumberedListActive,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryPink : AppTheme.backgroundTertiary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppTheme.textPrimary,
          size: 24,
        ),
      ),
    );
  }

  void _showImageOptions() {
    setState(() {
      _isModalOpen = true;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageFromCamera();
            },
            child: const Text('Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImageFromGallery();
            },
            child: const Text('Galeri'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showFilePicker();
            },
            child: const Text('Dosya'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Vazgeç'),
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isModalOpen = false;
        });
      }
    });
  }

  void _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeri hatası: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _uploadFile(File(file.path!));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçimi hatası: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      final noteId = _currentNoteId;
      if (noteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Not oluşturulmadan dosya yüklenemez'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
        return;
      }
      final fileName = p.basename(file.path);
      final uploaded = await AnnotationService().uploadFile(
        file,
        fileName,
        noteId: noteId,
      );

      final attachment = NoteAttachment(
        id: uploaded.id,
        name: uploaded.fileName,
        path: uploaded.fileUrl,
        type: uploaded.fileType == 'image'
            ? AttachmentType.image
            : AttachmentType.document,
        size: uploaded.fileSize,
        createdAt: uploaded.createdAt,
      );
      context.read<NotesProvider>().addAttachmentToNote(noteId, attachment);

      // Refresh the note to show the new attachment
      if (mounted) {
        await context.read<NotesProvider>().loadFromSupabase();
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dosya başarıyla yüklendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya yükleme hatası: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header - Catat style
                _buildHeader(),

                // Content area
                Expanded(child: _buildContentArea()),
              ],
            ),

            // Floating buttons - Catat style
            if (_isDrawingMode)
              Positioned(
                left: 12,
                top: mediaQuery.padding.top + 140,
                child: DrawingToolbar(
                  settings: _drawingSettings,
                  onSettingsChanged: (settings) {
                    setState(() {
                      _drawingSettings = settings;
                    });
                  },
                  onUndo: () {
                    setState(() {
                      if (_drawingData.paths.isNotEmpty) {
                        final newPaths = List<DrawingPath>.from(
                          _drawingData.paths,
                        );
                        newPaths.removeLast();
                        _drawingData = _drawingData.copyWith(paths: newPaths);
                      }
                    });
                  },
                  onClear: () {
                    setState(() {
                      _drawingData = DrawingData(
                        paths: [],
                        canvasSize: Size.zero,
                      );
                    });
                  },
                  onExit: () {
                    _activateDrawingMode();
                  },
                  canUndo: _drawingData.paths.isNotEmpty,
                  maxHeight:
                      mediaQuery.size.height -
                      (mediaQuery.padding.top +
                          180 +
                          mediaQuery.padding.bottom),
                ),
              ),
            if (!_isDrawingMode) _buildFloatingButtons(),
            // Klavye açıkken kapatma butonu
            if (isKeyboardVisible && !_isDrawingMode)
              _buildKeyboardCloseButton(),
            FloatingChatBubble(
              isModalOpen: _isModalOpen,
              hideInFileAnnotation: _isInFileAnnotation,
              extraBottomOffset: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () {
                  if (_hasChanges) {
                    _autoSave();
                  }
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: AppTheme.spacingM),

              // Undo/Redo buttons - use drawing history in drawing mode, note history otherwise
              IconButton(
                onPressed: _isDrawingMode
                    ? (_drawingHistoryIndex > 0 ? () => _undoDrawing() : null)
                    : (_canUndoNote() ? () => _undoNote() : null),
                icon: Icon(
                  Icons.undo,
                  color:
                      (_isDrawingMode
                          ? _drawingHistoryIndex > 0
                          : _canUndoNote())
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              IconButton(
                onPressed: _isDrawingMode
                    ? (_drawingHistoryIndex < _drawingHistory.length - 1
                          ? () => _redoDrawing()
                          : null)
                    : (_canRedoNote() ? () => _redoNote() : null),
                icon: Icon(
                  Icons.redo,
                  color:
                      (_isDrawingMode
                          ? _drawingHistoryIndex < _drawingHistory.length - 1
                          : _canRedoNote())
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const Spacer(),

              // Chatbot button - removed since we now have floating bubble
              const SizedBox(width: AppTheme.spacingS),

              // Attachment button
              IconButton(
                onPressed: _showExistingFiles,
                icon: Icon(
                  Icons.attach_file,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: AppTheme.spacingS),

              // Three dots menu
              IconButton(
                onPressed: _showOptionsMenu,
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Centered saving/saved indicator
          if (_isSaving || _justSaved)
            IgnorePointer(
              ignoring: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPrimary.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    ...AppTheme.cardShadow,
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primaryPink.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryPink,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryPink,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      color: AppTheme.backgroundPrimary,
      child: Column(
        children: [
          // Date and title
          _buildTitleSection(),

          // Main editor
          Expanded(child: _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: AppTheme.fontWeightNormal,
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  onChanged: (_) => _onContentChanged(),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSizeXLarge,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Başlıksız',
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Consumer<NotesProvider>(
            builder: (context, provider, _) {
              final options = provider.categories
                  .where((cat) => cat != 'all')
                  .toList(growable: false);
              if (!options.contains(_selectedCategory)) {
                if (options.isNotEmpty) {
                  _selectedCategory = options.first;
                } else {
                  _selectedCategory = 'general';
                }
              }
              if (options.isEmpty) {
                return const SizedBox.shrink();
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedCategory,
                  thumbColor: AppTheme.primaryPink.withOpacity(0.15),
                  backgroundColor: AppTheme.backgroundTertiary.withOpacity(0.8),
                  children: {
                    for (final cat in options)
                      cat: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: 6,
                        ),
                        child: Text(provider.categoryLabel(cat)),
                      ),
                  },
                  onValueChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCategory = value;
                    });
                    if (_currentNoteId != null) {
                      provider.setNoteCategoryRemote(_currentNoteId!, value);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final hasList = _hasListLikeMarkers(
      _quillController.document.toPlainText(),
    );
    return Container(
      padding: hasList
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      decoration: _isDrawingMode
          ? BoxDecoration(
              border: Border.all(color: AppTheme.primaryPink, width: 2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            )
          : null,
      child: Stack(
        children: [
          // Text editor - always visible
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _bodyScrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.only(
                  bottom: keyboardInset > 0
                      ? keyboardInset + AppTheme.spacingL
                      : AppTheme.spacingL,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_todos.isNotEmpty)
                        TodoListWidget(
                          todos: _todos,
                          onTodosChanged: (todos) {
                            setState(() {
                              _todos = todos;
                            });
                            _onContentChanged();
                          },
                          onDelete: () {
                            setState(() {
                              _todos = [];
                            });
                            _onContentChanged();
                          },
                        ),
                      DefaultTextStyle.merge(
                        style: AppTheme.textTheme.bodyLarge,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: AppTheme.primaryPink,
                              selectionColor: AppTheme.primaryPink
                                  .withOpacity(0.18),
                              selectionHandleColor: AppTheme.primaryPink,
                            ),
                          ),
                          child: GestureDetector(
                            onDoubleTapDown: (details) {
                              if (!_isDrawingMode) {
                                _handleDoubleTap(details.globalPosition);
                              }
                            },
                            child: quill.QuillEditor.basic(
                              controller: _quillController,
                              focusNode: _bodyFocusNode,
                              scrollController: null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Drawing canvas overlay - always present, interactive only in drawing mode
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Update canvas size if it's different
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                if (_drawingData.canvasSize != size) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _drawingData = _drawingData.copyWith(canvasSize: size);
                    });
                  });
                }

                // Get scroll offset safely - handle QuillEditor's scroll
                double scrollOffset = _currentScrollOffset;
                try {
                  if (_bodyScrollController.hasClients) {
                    scrollOffset = _bodyScrollController.offset;
                  }
                } catch (e) {
                  // If scroll controller error, use last known offset
                  scrollOffset = _currentScrollOffset;
                }

                return _isDrawingMode
                    ? DrawingCanvas(
                        drawingData: _drawingData,
                        settings: _drawingSettings,
                        onDrawingChanged: (newDrawingData) {
                          // Always update to the new data from canvas
                          // The canvas ensures it has the latest state
                          setState(() {
                            _drawingData = newDrawingData;
                          });
                          _onDrawingChanged();
                        },
                        isEnabled: true,
                        viewportScrollOffset: scrollOffset,
                      )
                    : IgnorePointer(
                        child: DrawingCanvas(
                          drawingData: _drawingData,
                          settings: _drawingSettings,
                          onDrawingChanged: (newDrawingData) {
                            // No-op when not in drawing mode
                          },
                          isEnabled: false,
                          viewportScrollOffset: scrollOffset,
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.padding.bottom;

    if (keyboardInset > 0) {
      return const SizedBox.shrink();
    }

    final bottomOffset = keyboardInset > 0
        ? keyboardInset + AppTheme.spacingM
        : AppTheme.spacingXXL + safeBottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      bottom: bottomOffset,
      left: AppTheme.spacingL,
      right: AppTheme.spacingL,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: EdgeInsets.only(
          bottom: keyboardInset > 0 ? AppTheme.spacingXS : AppTheme.spacingS,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.borderLight.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolbarButton(
                    icon: CupertinoIcons.textformat,
                    onTap: _showTextFormattingMenu,
                  ),
                  _buildToolbarButton(
                    icon: CupertinoIcons.photo,
                    onTap: _showImageOptions,
                  ),
                  _buildToolbarButton(
                    icon: CupertinoIcons.square_list,
                    onTap: _todos.isEmpty
                        ? () {
                            setState(() {
                              _todos = [
                                TodoItem(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  text: '',
                                  createdAt: DateTime.now(),
                                ),
                              ];
                            });
                            _onContentChanged();
                          }
                        : null,
                    isActive: _todos.isNotEmpty,
                  ),
                  _buildToolbarButton(
                    icon: CupertinoIcons.pen,
                    onTap: _toggleDrawingMode,
                    isActive: _isDrawingMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryPink : AppTheme.backgroundTertiary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isActive
              ? Colors.white
              : (onTap == null ? AppTheme.textTertiary : AppTheme.textPrimary),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildKeyboardCloseButton() {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Positioned(
      bottom: keyboardInset + 16,
      right: AppTheme.spacingL,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              FocusScope.of(context).unfocus();
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.borderLight.withOpacity(0.4),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.keyboard_chevron_compact_down,
                color: AppTheme.textPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _addTodoItem() {
    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      createdAt: DateTime.now(),
    );
    setState(() {
      _todos.insert(0, newTodo);
    });
    _onContentChanged();
  }

  // ignore: unused_element
  void _editTodoText(TodoItem todo) {
    final controller = TextEditingController(text: todo.text);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Görevi Düzenle'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingM),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Görev metnini girin',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final index = _todos.indexWhere((t) => t.id == todo.id);
                  if (index != -1) {
                    _todos[index] = _todos[index].copyWith(
                      text: controller.text.trim(),
                    );
                  }
                });
                _onContentChanged();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showTitleEditDialog() {
    final controller = TextEditingController(text: _titleController.text);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Başlığı Düzenle'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingM),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Başlık girin...',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _titleController.text = controller.text;
              _onContentChanged();
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(NoteFile file) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: file.fileType == 'image'
              ? Image.network(
                  file.fileUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.backgroundTertiary,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  },
                )
              : Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insert_drive_file),
                ),
        ),
        title: Text(file.fileName),
        subtitle: Text('${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () async {
            final uri = Uri.parse(file.fileUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _isInFileAnnotation = true;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'enhanced_file_annotation'),
              builder: (context) => EnhancedFileAnnotationScreen(file: file),
            ),
          ).then((_) {
            setState(() {
              _isInFileAnnotation = false;
            });
          });
        },
      ),
    );
  }
}
