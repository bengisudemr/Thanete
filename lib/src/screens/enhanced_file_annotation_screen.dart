import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/providers/enhanced_annotation_provider.dart';
import 'package:thanette/src/widgets/enhanced_annotation_toolbar.dart';
import 'package:thanette/src/widgets/enhanced_annotation_painter.dart';
import 'package:thanette/src/widgets/floating_chat_bubble.dart';
// import removed: text notes feature disabled
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class EnhancedFileAnnotationScreen extends StatefulWidget {
  final NoteFile file;

  const EnhancedFileAnnotationScreen({Key? key, required this.file})
    : super(key: key);

  @override
  State<EnhancedFileAnnotationScreen> createState() =>
      _EnhancedFileAnnotationScreenState();
}

class _EnhancedFileAnnotationScreenState
    extends State<EnhancedFileAnnotationScreen>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  Timer? _toolbarTimer;
  bool _showLayerPanel = false;
  bool _showExportOptions = false;
  // Text properties panel state removed

  late AnimationController _toolbarAnimationController;
  late AnimationController _layerPanelAnimationController;
  late AnimationController _exportAnimationController;
  // Text properties animation controller removed (text feature disabled)

  late Animation<double> _toolbarAnimation;
  late Animation<double> _layerPanelAnimation;
  late Animation<double> _exportAnimation;
  // Text properties animation removed

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Initialize animations
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _layerPanelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exportAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // _textPropertiesAnimationController removed

    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeInOut,
    );
    _layerPanelAnimation = CurvedAnimation(
      parent: _layerPanelAnimationController,
      curve: Curves.easeInOut,
    );
    _exportAnimation = CurvedAnimation(
      parent: _exportAnimationController,
      curve: Curves.easeInOut,
    );
    // _textPropertiesAnimation removed

    // Initialize annotation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnhancedAnnotationProvider>().initializeAnnotation(
        widget.file,
      );
    });

    // Auto-hide toolbar
    _startToolbarTimer();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _toolbarTimer?.cancel();
    _toolbarAnimationController.dispose();
    _layerPanelAnimationController.dispose();
    _exportAnimationController.dispose();
    // _textPropertiesAnimationController removed
    super.dispose();
  }

  void _startToolbarTimer() {
    _toolbarTimer?.cancel();
    _toolbarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _toolbarAnimationController.reverse();
      }
    });
  }

  void _showToolbarTemporarily() {
    _toolbarAnimationController.forward();
    _startToolbarTimer();
  }

  void _toggleExportOptions() {
    setState(() {
      _showExportOptions = !_showExportOptions;
    });

    if (_showExportOptions) {
      _exportAnimationController.forward();
    } else {
      _exportAnimationController.reverse();
    }
  }

  // _toggleTextPropertiesPanel removed (text feature disabled)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<EnhancedAnnotationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
              ),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return Stack(
            children: [
              // Main content area
              GestureDetector(
                onTap: _showToolbarTemporarily,
                // Text note adding disabled: no-op on double tap
                onDoubleTap: () {},
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // File viewer
                      _buildFileViewer(),

                      // Drawing layer
                      _buildDrawingLayer(provider),

                      // Text notes layer removed
                    ],
                  ),
                ),
              ),

              // Vertical toolbar on the right
              Positioned(
                top: MediaQuery.of(context).padding.top + 85,
                right: 16,
                child: AnimatedBuilder(
                  animation: _toolbarAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(100 * (1 - _toolbarAnimation.value), 0),
                      child: Opacity(
                        opacity: _toolbarAnimation.value,
                        child: _buildVerticalToolbar(provider),
                      ),
                    );
                  },
                ),
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: _buildBackButton(),
              ),

              // Toolbar toggle button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: _buildToolbarToggleButton(),
              ),

              // Layer panel
              if (_showLayerPanel) _buildLayerPanel(provider),

              // Export options panel
              if (_showExportOptions) _buildExportOptionsPanel(provider),

              // Text properties panel removed

              // Bottom status bar removed

              // AI Assistant bubble
              FloatingChatBubble(isModalOpen: _showExportOptions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(EnhancedAnnotationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              provider.initializeAnnotation(widget.file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer() {
    if (widget.file.fileType == 'image') {
      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.file.fileUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Resim yüklenemedi',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else if (widget.file.fileType == 'pdf') {
      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: SfPdfViewer.network(
              widget.file.fileUrl,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              onDocumentLoadFailed: (details) {
                print('PDF load failed: $details');
              },
            ),
          ),
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 16),
            Text(
              'Bu dosya türü desteklenmiyor',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDrawingLayer(EnhancedAnnotationProvider provider) {
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: (details) {
          final localPosition = details.localPosition;
          if (provider.currentTool == AnnotationTool.eraser) {
            provider.eraseAtPoint(localPosition);
          } else if (provider.currentTool == AnnotationTool.pen ||
              provider.currentTool == AnnotationTool.highlighter) {
            provider.startDrawing(localPosition);
          } else if (provider.currentTool == AnnotationTool.shapes ||
              provider.currentTool == AnnotationTool.arrows) {
            provider.startShapeDrawing(localPosition);
          }
        },
        onPanUpdate: (details) {
          final localPosition = details.localPosition;
          if (provider.currentTool == AnnotationTool.eraser) {
            provider.eraseAtPoint(localPosition);
          } else if (provider.currentTool == AnnotationTool.pen ||
              provider.currentTool == AnnotationTool.highlighter) {
            provider.updateDrawing(localPosition);
          } else if (provider.currentTool == AnnotationTool.shapes ||
              provider.currentTool == AnnotationTool.arrows) {
            provider.updateShapeDrawing(localPosition);
          }
        },
        onPanEnd: (details) {
          if (provider.currentTool == AnnotationTool.pen ||
              provider.currentTool == AnnotationTool.highlighter) {
            provider.endDrawing();
          } else if (provider.currentTool == AnnotationTool.shapes ||
              provider.currentTool == AnnotationTool.arrows) {
            provider.endShapeDrawing(details.localPosition);
          }
        },
        child: CustomPaint(
          painter: EnhancedAnnotationPainter(
            allStrokes: provider.allStrokes,
            currentStrokes: provider.currentStrokes,
            shapes: provider.shapes,
            textNotes: provider.textNotes,
            layers: provider.layers,
            activeLayerIndex: provider.activeLayerIndex,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  // Text notes layer removed

  Widget _buildVerticalToolbar(EnhancedAnnotationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          // Drawing tools
          _buildVerticalToolButton(
            icon: Icons.edit_outlined,
            tool: AnnotationTool.pen,
            tooltip: 'Kalem',
            isActive: provider.currentTool == AnnotationTool.pen,
            onTap: () {
              provider.setTool(AnnotationTool.pen);
              _showToolbarTemporarily();
            },
          ),
          _buildVerticalToolButton(
            icon: Icons.highlight,
            tool: AnnotationTool.highlighter,
            tooltip: 'Vurgulayıcı',
            isActive: provider.currentTool == AnnotationTool.highlighter,
            onTap: () {
              provider.setTool(AnnotationTool.highlighter);
              _showToolbarTemporarily();
            },
          ),
          _buildVerticalToolButton(
            icon: Icons.auto_fix_high,
            tool: AnnotationTool.eraser,
            tooltip: 'Silgi',
            isActive: provider.currentTool == AnnotationTool.eraser,
            onTap: () {
              provider.setTool(AnnotationTool.eraser);
              _showToolbarTemporarily();
            },
          ),

          const SizedBox(height: 8),

          // Text tool removed
          const SizedBox(height: 8),

          // Shape tools
          _buildVerticalToolButton(
            icon: Icons.shape_line_outlined,
            tool: AnnotationTool.shapes,
            tooltip: 'Şekiller',
            isActive: provider.currentTool == AnnotationTool.shapes,
            onTap: () {
              provider.setTool(AnnotationTool.shapes);
              _showToolbarTemporarily();
            },
          ),
          _buildVerticalToolButton(
            icon: Icons.arrow_forward,
            tool: AnnotationTool.arrows,
            tooltip: 'Oklar',
            isActive: provider.currentTool == AnnotationTool.arrows,
            onTap: () {
              provider.setTool(AnnotationTool.arrows);
              _showToolbarTemporarily();
            },
          ),

          const SizedBox(height: 8),

          // Action tools
          _buildVerticalToolButton(
            icon: Icons.undo,
            tooltip: 'Geri Al',
            isEnabled: provider.canUndo,
            onTap: provider.canUndo
                ? () {
                    provider.undo();
                    _showToolbarTemporarily();
                  }
                : null,
          ),
          _buildVerticalToolButton(
            icon: Icons.redo,
            tooltip: 'Yinele',
            isEnabled: provider.canRedo,
            onTap: provider.canRedo
                ? () {
                    provider.redo();
                    _showToolbarTemporarily();
                  }
                : null,
          ),

          const SizedBox(height: 8),

          // Color picker
          _buildColorPickerButton(provider),

          // Stroke width picker
          _buildStrokeWidthButton(provider),

          const SizedBox(height: 8),

          // More options
          _buildVerticalToolButton(
            icon: Icons.more_horiz,
            tooltip: 'Daha Fazla',
            onTap: _toggleExportOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalToolButton({
    required IconData icon,
    AnnotationTool? tool,
    required String tooltip,
    bool isActive = false,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7B61FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Icon(
            icon,
            color: isActive
                ? Colors.white
                : (isEnabled
                      ? const Color(0xFF6B7280)
                      : const Color(0xFFD1D5DB)),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerButton(EnhancedAnnotationProvider provider) {
    return GestureDetector(
      onTap: () => _showColorPickerDialog(provider),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: provider.currentColor,
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
    );
  }

  Widget _buildStrokeWidthButton(EnhancedAnnotationProvider provider) {
    return GestureDetector(
      onTap: () => _showStrokeWidthDialog(provider),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Center(
          child: Container(
            width: 24,
            height: provider.currentStrokeWidth.clamp(1.0, 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildToolbarToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          if (_toolbarAnimationController.isCompleted) {
            _toolbarAnimationController.reverse();
          } else {
            _toolbarAnimationController.forward();
          }
        },
        icon: Icon(
          _toolbarAnimationController.isCompleted
              ? Icons.keyboard_hide
              : Icons.keyboard,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildLayerPanel(EnhancedAnnotationProvider provider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: AnimatedBuilder(
        animation: _layerPanelAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(200 * (1 - _layerPanelAnimation.value), 0),
            child: Opacity(
              opacity: _layerPanelAnimation.value,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Katmanlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.layers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final layer = entry.value;
                      return _buildLayerItem(provider, index, layer);
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayerItem(
    EnhancedAnnotationProvider provider,
    int index,
    AnnotationLayer layer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            layer.isVisible ? Icons.visibility : Icons.visibility_off,
            size: 16,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              layer.name,
              style: TextStyle(
                fontSize: 14,
                color: provider.activeLayerIndex == index
                    ? const Color(0xFF7B61FF)
                    : const Color(0xFF374151),
                fontWeight: provider.activeLayerIndex == index
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => provider.toggleLayerVisibility(index),
            child: Icon(
              layer.isLocked ? Icons.lock : Icons.lock_open,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Text properties panel removed

  // _buildCompactTextPropertyButton removed

  Widget _buildExportOptionsPanel(EnhancedAnnotationProvider provider) {
    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleExportOptions,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _exportAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 100 * (1 - _exportAnimation.value)),
                child: Opacity(
                  opacity: _exportAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        const Text(
                          'Export Seçenekleri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildExportOption(
                              icon: Icons.image,
                              label: 'PNG',
                              onTap: () {
                                provider.exportAnnotation();
                                _toggleExportOptions();
                              },
                            ),
                            _buildExportOption(
                              icon: Icons.picture_as_pdf,
                              label: 'PDF',
                              onTap: () {
                                provider.exportAnnotation();
                                _toggleExportOptions();
                              },
                            ),
                            _buildExportOption(
                              icon: Icons.share,
                              label: 'Paylaş',
                              onTap: () {
                                provider.shareAnnotation();
                                _toggleExportOptions();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF7B61FF), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // Status bar removed

  // Helper methods removed

  // Text note adding removed

  // Clear dialog removed (text notes disabled)

  void _showColorPickerDialog(EnhancedAnnotationProvider provider) {
    final colors = [
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renk Seçin'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                provider.setColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: provider.currentColor == color
                        ? const Color(0xFF7B61FF)
                        : Colors.grey,
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
    );
  }

  void _showStrokeWidthDialog(EnhancedAnnotationProvider provider) {
    final strokeWidths = [1.0, 2.0, 4.0, 6.0, 8.0, 12.0, 16.0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalınlık Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: strokeWidths.map((width) {
            return GestureDetector(
              onTap: () {
                provider.setStrokeWidth(width);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: provider.currentStrokeWidth == width
                      ? const Color(0xFF7B61FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: width.clamp(1.0, 30.0),
                    height: width.clamp(1.0, 30.0),
                    decoration: BoxDecoration(
                      color: provider.currentStrokeWidth == width
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
    );
  }
}
