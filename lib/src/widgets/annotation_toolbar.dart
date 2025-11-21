import 'package:flutter/material.dart';
import 'package:thanette/src/providers/annotation_provider.dart';

class AnnotationToolbar extends StatefulWidget {
  final Function(AnnotationTool) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final AnnotationTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;

  const AnnotationToolbar({
    Key? key,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    this.onUndo,
    this.onRedo,
    required this.onSave,
    required this.onClear,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
  }) : super(key: key);

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  bool _showColorPicker = false;
  bool _showStrokeWidthPicker = false;

  final List<Color> _colors = [
    const Color(0xFF374151), // Gray
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF000000), // Black
  ];

  final List<double> _strokeWidths = [1.0, 2.0, 4.0, 6.0, 8.0, 12.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolButton(
                  icon: Icons.edit_outlined,
                  tool: AnnotationTool.pen,
                  tooltip: 'Kalem',
                ),
                _buildToolButton(
                  icon: Icons.auto_fix_high,
                  tool: AnnotationTool.eraser,
                  tooltip: 'Silgi',
                ),
                _buildToolButton(
                  icon: Icons.text_fields,
                  tool: AnnotationTool.text,
                  tooltip: 'Metin',
                ),
                _buildToolButton(
                  icon: Icons.open_with,
                  tool: AnnotationTool.select,
                  tooltip: 'Seç',
                ),
                const SizedBox(width: 8),
                _buildColorButton(),
                _buildStrokeWidthButton(),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.undo,
                  onPressed: widget.onUndo,
                  tooltip: 'Geri Al',
                  isEnabled: widget.onUndo != null,
                ),
                _buildActionButton(
                  icon: Icons.redo,
                  onPressed: widget.onRedo,
                  tooltip: 'Yinele',
                  isEnabled: widget.onRedo != null,
                ),
                _buildActionButton(
                  icon: Icons.save_outlined,
                  onPressed: widget.onSave,
                  tooltip: 'Kaydet',
                  isEnabled: true,
                ),
                _buildActionButton(
                  icon: Icons.clear_all,
                  onPressed: widget.onClear,
                  tooltip: 'Temizle',
                  isEnabled: true,
                ),
              ],
            ),
          ),

          // Color picker
          if (_showColorPicker) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      widget.onColorChanged(color);
                      setState(() {
                        _showColorPicker = false;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.currentColor == color
                              ? const Color(0xFF7B61FF)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Stroke width picker
          if (_showStrokeWidthPicker) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _strokeWidths.map((width) {
                  return GestureDetector(
                    onTap: () {
                      widget.onStrokeWidthChanged(width);
                      setState(() {
                        _showStrokeWidthPicker = false;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: widget.currentStrokeWidth == width
                            ? const Color(0xFF7B61FF)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: width,
                          height: width,
                          decoration: BoxDecoration(
                            color: widget.currentStrokeWidth == width
                                ? Colors.white
                                : const Color(0xFF374151),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required AnnotationTool tool,
    required String tooltip,
  }) {
    final isSelected = widget.currentTool == tool;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onToolChanged(tool),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton() {
    return Tooltip(
      message: 'Renk',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showColorPicker = !_showColorPicker;
            _showStrokeWidthPicker = false;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showColorPicker
                ? const Color(0xFF7B61FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthButton() {
    return Tooltip(
      message: 'Kalınlık',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showStrokeWidthPicker = !_showStrokeWidthPicker;
            _showColorPicker = false;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showStrokeWidthPicker
                ? const Color(0xFF7B61FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 20,
              height: widget.currentStrokeWidth,
              decoration: BoxDecoration(
                color: _showStrokeWidthPicker
                    ? Colors.white
                    : const Color(0xFF6B7280),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isEnabled,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? const Color(0xFF6B7280)
                : const Color(0xFFD1D5DB),
            size: 20,
          ),
        ),
      ),
    );
  }
}
