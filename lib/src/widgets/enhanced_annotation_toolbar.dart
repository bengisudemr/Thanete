import 'package:flutter/material.dart';

enum AnnotationTool { pen, highlighter, eraser, text, shapes, arrows, select }

enum ShapeType { rectangle, circle, line, arrow, highlight }

class EnhancedAnnotationToolbar extends StatefulWidget {
  final Function(AnnotationTool) onToolChanged;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;
  final Function(ShapeType)? onShapeChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final AnnotationTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final ShapeType? currentShape;

  const EnhancedAnnotationToolbar({
    Key? key,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    this.onShapeChanged,
    this.onUndo,
    this.onRedo,
    required this.onSave,
    required this.onClear,
    required this.onExport,
    required this.onShare,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.currentShape,
  }) : super(key: key);

  @override
  State<EnhancedAnnotationToolbar> createState() =>
      _EnhancedAnnotationToolbarState();
}

class _EnhancedAnnotationToolbarState extends State<EnhancedAnnotationToolbar>
    with TickerProviderStateMixin {
  bool _showColorPicker = false;
  bool _showStrokeWidthPicker = false;
  bool _showShapePicker = false;
  bool _showMoreOptions = false;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  final List<Color> _colors = [
    const Color(0xFF374151), // Gray
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF000000), // Black
    const Color(0xFFFFD700), // Gold
    const Color(0xFF00CED1), // Dark Turquoise
  ];

  final List<double> _strokeWidths = [1.0, 2.0, 4.0, 6.0, 8.0, 12.0, 16.0];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
      _showStrokeWidthPicker = false;
      _showShapePicker = false;
      _showMoreOptions = false;
    });

    if (_showColorPicker) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _toggleStrokeWidthPicker() {
    setState(() {
      _showStrokeWidthPicker = !_showStrokeWidthPicker;
      _showColorPicker = false;
      _showShapePicker = false;
      _showMoreOptions = false;
    });

    if (_showStrokeWidthPicker) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _toggleShapePicker() {
    setState(() {
      _showShapePicker = !_showShapePicker;
      _showColorPicker = false;
      _showStrokeWidthPicker = false;
      _showMoreOptions = false;
    });

    if (_showShapePicker) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _toggleMoreOptions() {
    setState(() {
      _showMoreOptions = !_showMoreOptions;
      _showColorPicker = false;
      _showStrokeWidthPicker = false;
      _showShapePicker = false;
    });

    if (_showMoreOptions) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.edit_outlined,
                  tool: AnnotationTool.pen,
                  tooltip: 'Kalem',
                  isActive: widget.currentTool == AnnotationTool.pen,
                ),
                _buildToolButton(
                  icon: Icons.highlight,
                  tool: AnnotationTool.highlighter,
                  tooltip: 'Vurgulayıcı',
                  isActive: widget.currentTool == AnnotationTool.highlighter,
                ),
                _buildToolButton(
                  icon: Icons.auto_fix_high,
                  tool: AnnotationTool.eraser,
                  tooltip: 'Silgi',
                  isActive: widget.currentTool == AnnotationTool.eraser,
                ),
                _buildToolButton(
                  icon: Icons.text_fields,
                  tool: AnnotationTool.text,
                  tooltip: 'Metin',
                  isActive: widget.currentTool == AnnotationTool.text,
                ),
                _buildToolButton(
                  icon: Icons.shape_line_outlined,
                  tool: AnnotationTool.shapes,
                  tooltip: 'Şekiller',
                  isActive: widget.currentTool == AnnotationTool.shapes,
                ),
                _buildToolButton(
                  icon: Icons.arrow_forward,
                  tool: AnnotationTool.arrows,
                  tooltip: 'Oklar',
                  isActive: widget.currentTool == AnnotationTool.arrows,
                ),
                _buildToolButton(
                  icon: Icons.open_with,
                  tool: AnnotationTool.select,
                  tooltip: 'Seç',
                  isActive: widget.currentTool == AnnotationTool.select,
                ),
              ],
            ),
          ),

          // Secondary toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorButton(),
                _buildStrokeWidthButton(),
                if (widget.currentTool == AnnotationTool.shapes ||
                    widget.currentTool == AnnotationTool.arrows)
                  _buildShapeButton(),
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
                _buildMoreButton(),
              ],
            ),
          ),

          // Expandable sections
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  children: [
                    if (_showColorPicker) _buildColorPicker(),
                    if (_showStrokeWidthPicker) _buildStrokeWidthPicker(),
                    if (_showShapePicker) _buildShapePicker(),
                    if (_showMoreOptions) _buildMoreOptions(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required AnnotationTool tool,
    required String tooltip,
    required bool isActive,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onToolChanged(tool),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7B61FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton() {
    return Tooltip(
      message: 'Renk',
      child: GestureDetector(
        onTap: _toggleColorPicker,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showColorPicker ? const Color(0xFF7B61FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
        onTap: _toggleStrokeWidthPicker,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showStrokeWidthPicker
                ? const Color(0xFF7B61FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: widget.currentStrokeWidth.clamp(1.0, 8.0),
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

  Widget _buildShapeButton() {
    return Tooltip(
      message: 'Şekil',
      child: GestureDetector(
        onTap: _toggleShapePicker,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showShapePicker ? const Color(0xFF7B61FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Icon(
            _getShapeIcon(),
            color: _showShapePicker ? Colors.white : const Color(0xFF6B7280),
            size: 20,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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

  Widget _buildMoreButton() {
    return Tooltip(
      message: 'Daha Fazla',
      child: GestureDetector(
        onTap: _toggleMoreOptions,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showMoreOptions ? const Color(0xFF7B61FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Icon(
            Icons.more_horiz,
            color: _showMoreOptions ? Colors.white : const Color(0xFF6B7280),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Renk Seçin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () {
                  widget.onColorChanged(color);
                  _toggleColorPicker();
                },
                child: Container(
                  width: 36,
                  height: 36,
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
        ],
      ),
    );
  }

  Widget _buildStrokeWidthPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalınlık Seçin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _strokeWidths.map((width) {
              return GestureDetector(
                onTap: () {
                  widget.onStrokeWidthChanged(width);
                  _toggleStrokeWidthPicker();
                },
                child: Container(
                  width: 44,
                  height: 44,
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
                      width: width.clamp(1.0, 20.0),
                      height: width.clamp(1.0, 20.0),
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
        ],
      ),
    );
  }

  Widget _buildShapePicker() {
    final shapes = [
      (ShapeType.rectangle, Icons.rectangle_outlined, 'Dikdörtgen'),
      (ShapeType.circle, Icons.circle_outlined, 'Daire'),
      (ShapeType.line, Icons.horizontal_rule, 'Çizgi'),
      (ShapeType.arrow, Icons.arrow_forward, 'Ok'),
      (ShapeType.highlight, Icons.highlight, 'Vurgu'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şekil Seçin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: shapes.map((shape) {
              return GestureDetector(
                onTap: () {
                  widget.onShapeChanged?.call(shape.$1);
                  _toggleShapePicker();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.currentShape == shape.$1
                        ? const Color(0xFF7B61FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    shape.$2,
                    color: widget.currentShape == shape.$1
                        ? Colors.white
                        : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMoreActionButton(
            icon: Icons.save_outlined,
            label: 'Kaydet',
            onTap: widget.onSave,
          ),
          _buildMoreActionButton(
            icon: Icons.clear_all,
            label: 'Temizle',
            onTap: widget.onClear,
          ),
          _buildMoreActionButton(
            icon: Icons.download,
            label: 'Export',
            onTap: widget.onExport,
          ),
          _buildMoreActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onTap: widget.onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _toggleMoreOptions();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  IconData _getShapeIcon() {
    switch (widget.currentShape) {
      case ShapeType.rectangle:
        return Icons.rectangle_outlined;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.line:
        return Icons.horizontal_rule;
      case ShapeType.arrow:
        return Icons.arrow_forward;
      case ShapeType.highlight:
        return Icons.highlight;
      default:
        return Icons.shape_line_outlined;
    }
  }
}
