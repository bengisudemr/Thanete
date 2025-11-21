import 'package:flutter/material.dart';
import 'package:thanette/src/models/file_annotation.dart';

class TextNoteWidget extends StatefulWidget {
  final TextNote note;
  final Function(String) onTextChanged;
  final VoidCallback onDelete;

  const TextNoteWidget({
    Key? key,
    required this.note,
    required this.onTextChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<TextNoteWidget> createState() => _TextNoteWidgetState();
}

class _TextNoteWidgetState extends State<TextNoteWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
    _focusNode = FocusNode();

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
      left: widget.note.position.dx + _dragOffset.dx,
      top: widget.note.position.dy + _dragOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 200,
            minHeight: 40,
          ),
          decoration: BoxDecoration(
            color: widget.note.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing
                  ? const Color(0xFF7B61FF)
                  : const Color(0xFFE5E7EB),
              width: _isEditing ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: widget.note.backgroundColor.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Text field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: widget.note.textColor,
                    fontSize: widget.note.fontSize,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Not yazın...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  onChanged: (text) {
                    widget.onTextChanged(text);
                  },
                ),
              ),

              // Delete button
              if (_isEditing)
                Positioned(
                  right: 4,
                  top: 4,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
