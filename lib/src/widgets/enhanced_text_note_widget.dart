import 'package:flutter/material.dart';
import 'package:thanette/src/models/file_annotation.dart';

class EnhancedTextNoteWidget extends StatefulWidget {
  final TextNote note;
  final Function(String) onTextChanged;
  final VoidCallback onDelete;
  final Function(Offset)? onPositionChanged;
  final Function(Color)? onColorChanged;
  final Function(double)? onFontSizeChanged;

  const EnhancedTextNoteWidget({
    Key? key,
    required this.note,
    required this.onTextChanged,
    required this.onDelete,
    this.onPositionChanged,
    this.onColorChanged,
    this.onFontSizeChanged,
  }) : super(key: key);

  @override
  State<EnhancedTextNoteWidget> createState() => _EnhancedTextNoteWidgetState();
}

class _EnhancedTextNoteWidgetState extends State<EnhancedTextNoteWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  bool _isDragging = false;
  Offset _notePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
    _focusNode = FocusNode();
    _notePosition = widget.note.position;

    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _notePosition.dx,
      top: _notePosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          if (!_isEditing) {
            _isDragging = true;
            // Focus'u kaldır ki sürükleme başlasın
            _focusNode.unfocus();
          }
        },
        onPanUpdate: (details) {
          if (_isDragging && !_isEditing) {
            setState(() {
              _notePosition = Offset(
                _notePosition.dx + details.delta.dx,
                _notePosition.dy + details.delta.dy,
              );
            });
            widget.onPositionChanged?.call(_notePosition);
          }
        },
        onPanEnd: (details) {
          _isDragging = false;
        },
        onTap: () {
          if (!_isEditing) {
            _focusNode.requestFocus();
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 100,
            maxWidth: 300,
            minHeight: 40,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent, // Tamamen saydam arka plan
            borderRadius: BorderRadius.circular(8),
            border: _isEditing
                ? Border.all(color: const Color(0xFF7B61FF), width: 2)
                : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            boxShadow: _isEditing
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with drag handle and delete button
              Row(
                children: [
                  // Drag handle
                  if (!_isEditing)
                    Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: widget.note.textColor,
                        fontSize: widget.note.fontSize,
                        fontWeight: FontWeight.w600, // Metni daha belirgin yap
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(8),
                        filled: true,
                        fillColor: Colors.transparent, // Saydam arka plan
                      ),
                      maxLines: null,
                      onChanged: widget.onTextChanged,
                      onSubmitted: (value) {
                        _focusNode.unfocus();
                      },
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),

              // Formatting toolbar (shown when editing)
              if (_isEditing) _buildFormattingToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font size controls
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              final newSize = (widget.note.fontSize - 2).clamp(8.0, 32.0);
              widget.onFontSizeChanged?.call(newSize);
            },
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
          Text(
            '${widget.note.fontSize.toInt()}',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              final newSize = (widget.note.fontSize + 2).clamp(8.0, 32.0);
              widget.onFontSizeChanged?.call(newSize);
            },
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),

          const SizedBox(width: 8),

          // Color picker
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.note.textColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Background color picker
          GestureDetector(
            onTap: _showBackgroundColorPicker,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.note.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
            onPressed: widget.onDelete,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metin Rengi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorGrid(
                [
                  Colors.black,
                  Colors.white,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                  Colors.grey,
                ],
                (color) {
                  widget.onColorChanged?.call(color);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arka Plan Rengi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorGrid(
                [
                  Colors.transparent,
                  Colors.yellow.withOpacity(0.3),
                  Colors.green.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                  Colors.red.withOpacity(0.3),
                  Colors.orange.withOpacity(0.3),
                  Colors.purple.withOpacity(0.3),
                  Colors.pink.withOpacity(0.3),
                  Colors.grey.withOpacity(0.3),
                  Colors.white.withOpacity(0.8),
                ],
                (color) {
                  widget.onColorChanged?.call(color);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid(List<Color> colors, Function(Color) onColorSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    color == widget.note.textColor ||
                        color == widget.note.backgroundColor
                    ? const Color(0xFF7B61FF)
                    : Colors.grey,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
