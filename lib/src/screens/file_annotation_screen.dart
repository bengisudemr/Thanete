import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/providers/annotation_provider.dart';
import 'package:thanette/src/widgets/annotation_toolbar.dart';
import 'package:thanette/src/widgets/annotation_painter.dart';
import 'package:thanette/src/widgets/text_note_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FileAnnotationScreen extends StatefulWidget {
  final NoteFile file;

  const FileAnnotationScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<FileAnnotationScreen> createState() => _FileAnnotationScreenState();
}

class _FileAnnotationScreenState extends State<FileAnnotationScreen> {
  late TransformationController _transformationController;
  bool _showToolbar = true;
  Timer? _toolbarTimer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Initialize annotation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnotationProvider>().initializeAnnotation(widget.file);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _toolbarTimer?.cancel();
    super.dispose();
  }

  void _showToolbarTemporarily() {
    setState(() {
      _showToolbar = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<AnnotationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
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

          return Stack(
            children: [
              // Main content area
              GestureDetector(
                onTap: _showToolbarTemporarily,
                onDoubleTap: () {
                  if (provider.currentTool == AnnotationTool.text) {
                    _addTextNote(context, provider);
                  }
                },
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // File viewer
                      _buildFileViewer(),

                      // Drawing layer - show for pen and eraser tools
                      if (provider.currentTool == AnnotationTool.pen ||
                          provider.currentTool == AnnotationTool.eraser)
                        _buildDrawingLayer(provider),

                      // Text notes layer
                      _buildTextNotesLayer(provider),
                    ],
                  ),
                ),
              ),

              // Floating toolbar
              if (_showToolbar)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: AnnotationToolbar(
                    onToolChanged: (tool) {
                      provider.setTool(tool);
                      _showToolbarTemporarily();
                    },
                    onColorChanged: (color) {
                      provider.setColor(color);
                      _showToolbarTemporarily();
                    },
                    onStrokeWidthChanged: (width) {
                      provider.setStrokeWidth(width);
                      _showToolbarTemporarily();
                    },
                    onUndo: provider.canUndo
                        ? () {
                            provider.undo();
                            _showToolbarTemporarily();
                          }
                        : null,
                    onRedo: provider.canRedo
                        ? () {
                            provider.redo();
                            _showToolbarTemporarily();
                          }
                        : null,
                    onSave: () {
                      provider.saveAnnotation();
                      _showToolbarTemporarily();
                    },
                    onClear: () {
                      _showClearDialog(context, provider);
                    },
                    currentTool: provider.currentTool,
                    currentColor: provider.currentColor,
                    currentStrokeWidth: provider.currentStrokeWidth,
                  ),
                ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
                // Handle PDF load failure
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

  Widget _buildDrawingLayer(AnnotationProvider provider) {
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: (details) {
          final localPosition = details.localPosition;
          if (provider.currentTool == AnnotationTool.eraser) {
            provider.eraseAtPoint(localPosition);
          } else {
            provider.startDrawing(localPosition);
          }
        },
        onPanUpdate: (details) {
          final localPosition = details.localPosition;
          if (provider.currentTool == AnnotationTool.eraser) {
            provider.eraseAtPoint(localPosition);
          } else {
            provider.updateDrawing(localPosition);
          }
        },
        onPanEnd: (details) {
          if (provider.currentTool != AnnotationTool.eraser) {
            provider.endDrawing();
          }
        },
        child: CustomPaint(
          painter: AnnotationPainter(
            allStrokes: provider.allStrokes,
            currentStrokes: provider.currentStrokes,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildTextNotesLayer(AnnotationProvider provider) {
    return Stack(
      children: provider.textNotes.map((note) {
        return Positioned(
          left: note.position.dx,
          top: note.position.dy,
          child: TextNoteWidget(
            note: note,
            onTextChanged: (text) {
              provider.updateTextNote(note.id, text);
            },
            onDelete: () {
              provider.deleteTextNote(note.id);
            },
          ),
        );
      }).toList(),
    );
  }

  void _addTextNote(BuildContext context, AnnotationProvider provider) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(
      Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
    );

    provider.addTextNote(localPosition);
    _showToolbarTemporarily();
  }

  void _showClearDialog(BuildContext context, AnnotationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tüm Notları Sil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        content: const Text(
          'Tüm çizimler ve metin notları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'İptal',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAll();
              Navigator.of(context).pop();
              _showToolbarTemporarily();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
