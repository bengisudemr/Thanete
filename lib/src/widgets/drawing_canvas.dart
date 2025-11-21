import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:thanette/src/models/drawing.dart';

class DrawingCanvas extends StatefulWidget {
  final DrawingData drawingData;
  final DrawingSettings settings;
  final Function(DrawingData) onDrawingChanged;
  final bool isEnabled;
  final double viewportScrollOffset; // content scroll offset to anchor strokes

  const DrawingCanvas({
    super.key,
    required this.drawingData,
    required this.settings,
    required this.onDrawingChanged,
    this.isEnabled = true,
    this.viewportScrollOffset = 0.0,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  DrawingPath? _currentPath;
  late DrawingData _drawingData;
  int _activePointers = 0;
  bool get _shouldPassThrough =>
      _activePointers >= 2; // allow 2+ fingers to scroll

  // Apple Pencil tracking
  bool _isApplePencilActive = false;
  double? _lastPressure;
  double? _lastTilt;
  
  // Flag to prevent state overwrites during drawing operations
  bool _isProcessingDrawing = false;

  @override
  void initState() {
    super.initState();
    _drawingData = widget.drawingData;
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRITICAL: Never update _drawingData from widget if:
    // 1. We're currently drawing (_currentPath != null)
    // 2. We're processing a drawing operation (_isProcessingDrawing)
    // 3. Local state has more paths than widget (we have newer data)
    if (_currentPath != null || _isProcessingDrawing) {
      // Don't update - preserve local state during drawing
      return;
    }
    
    // Only update if widget data has more paths than our local data
    // This ensures we don't lose paths that were just added
    if (widget.drawingData.paths.length > _drawingData.paths.length) {
      // Widget has more paths - definitely update
      _drawingData = widget.drawingData;
    } else if (widget.drawingData.paths.length == _drawingData.paths.length) {
      // Same count - check if paths are actually different (undo/redo)
      if (oldWidget.drawingData.paths.length != widget.drawingData.paths.length) {
        // Path count changed (could be undo/redo)
        _drawingData = widget.drawingData;
      } else if (oldWidget.drawingData.paths.length > 0 &&
          widget.drawingData.paths.length > 0) {
        // Check if any path IDs are different (indicating actual change)
        bool hasChanges = false;
        for (int i = 0; i < widget.drawingData.paths.length; i++) {
          if (i >= oldWidget.drawingData.paths.length ||
              oldWidget.drawingData.paths[i].id !=
                  widget.drawingData.paths[i].id) {
            hasChanges = true;
            break;
          }
        }
        if (hasChanges) {
          _drawingData = widget.drawingData;
        }
      }
    }
    // If widget has fewer paths than local, don't update (preserve local state)
    // This prevents losing paths during parent rebuilds with stale data
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isEnabled) return;

    // Check if this is an Apple Pencil (stylus)
    _isApplePencilActive = event.kind == PointerDeviceKind.stylus;
    _lastPressure = event.pressure > 0 ? event.pressure : null;
    _lastTilt = event.tilt > 0 ? event.tilt : null;

    if (_isApplePencilActive) {
      print(
        'Apple Pencil detected - Pressure: $_lastPressure, Tilt: $_lastTilt',
      );
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.isEnabled || !_isApplePencilActive) return;

    // Update pressure and tilt for Apple Pencil
    _lastPressure = event.pressure > 0 ? event.pressure : _lastPressure;
    _lastTilt = event.tilt > 0 ? event.tilt : _lastTilt;

    // If we have a current path, update it with pressure-sensitive stroke width
    if (_currentPath != null && _lastPressure != null) {
      final baseStrokeWidth = widget.settings.strokeWidth;
      // Pressure ranges from 0.0 to 1.0, map it to stroke width variation
      // Light pressure: 0.3x, Normal: 1.0x, Heavy: 1.5x
      final pressureMultiplier = 0.3 + (_lastPressure! * 1.2);
      final dynamicStrokeWidth = baseStrokeWidth * pressureMultiplier;

      // Create a new paint with dynamic stroke width
      final dynamicPaint = widget.settings.paint;
      dynamicPaint.strokeWidth = dynamicStrokeWidth;

      final point = DrawingPoint(
        offset: event.localPosition,
        paint: dynamicPaint,
        pressure: _lastPressure,
        tilt: _lastTilt,
      );

      _currentPath = _currentPath!.copyWith(
        points: [..._currentPath!.points, point],
      );

      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _isApplePencilActive = false;
    _lastPressure = null;
    _lastTilt = null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) {
      print('Drawing canvas is not enabled');
      return;
    }

    // Don't start drawing if multiple pointers are active (scrolling)
    if (_activePointers >= 2) {
      return;
    }

    print('Drawing started at: ${details.localPosition}');
    print('Tool: ${widget.settings.tool}, Color: ${widget.settings.color}');

    // If eraser tool is selected, erase at the touch point
    if (widget.settings.tool == DrawingTool.eraser) {
      _erasePathsAtPoint(details.localPosition);
      return;
    }

    // Use pressure if available (from Apple Pencil)
    final basePaint = widget.settings.paint;
    final paint = _lastPressure != null
        ? (Paint()
            ..color = basePaint.color
            ..strokeWidth =
                basePaint.strokeWidth * (0.3 + (_lastPressure! * 1.2))
            ..strokeCap = basePaint.strokeCap
            ..strokeJoin = basePaint.strokeJoin
            ..style = basePaint.style
            ..blendMode = basePaint.blendMode)
        : basePaint;

    final point = DrawingPoint(
      // Store in canvas local coordinates (no scroll offset needed)
      offset: details.localPosition,
      paint: paint,
      pressure: _lastPressure,
      tilt: _lastTilt,
    );

    _currentPath = DrawingPath(
      points: [point],
      paint: paint,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    print('Created path with paint: ${paint.color}, pressure: $_lastPressure');
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;

    // Don't update drawing if multiple pointers are active (scrolling)
    if (_activePointers >= 2) {
      // Cancel current path if it exists
      if (_currentPath != null) {
        _currentPath = null;
        setState(() {});
      }
      return;
    }

    // If eraser tool is selected, erase at the touch point
    if (widget.settings.tool == DrawingTool.eraser) {
      _erasePathsAtPoint(details.localPosition);
      return;
    }

    if (_currentPath == null) return;

    // Use pressure if available (from Apple Pencil)
    final basePaint = widget.settings.paint;
    final paint = _lastPressure != null
        ? (Paint()
            ..color = basePaint.color
            ..strokeWidth =
                basePaint.strokeWidth * (0.3 + (_lastPressure! * 1.2))
            ..strokeCap = basePaint.strokeCap
            ..strokeJoin = basePaint.strokeJoin
            ..style = basePaint.style
            ..blendMode = basePaint.blendMode)
        : basePaint;

    final point = DrawingPoint(
      // Canvas local coordinates (no scroll offset needed)
      offset: details.localPosition,
      paint: paint,
      pressure: _lastPressure,
      tilt: _lastTilt,
    );

    _currentPath = _currentPath!.copyWith(
      points: [..._currentPath!.points, point],
    );

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled || _currentPath == null) return;

    print('Drawing ended. Path has ${_currentPath!.points.length} points');

    // If eraser tool, don't add the eraser path to the drawing
    if (widget.settings.tool != DrawingTool.eraser) {
      // Set flag to prevent didUpdateWidget from overwriting state
      _isProcessingDrawing = true;
      
      // Create a copy of current drawing data with the new path
      final completedPath = _currentPath!;
      final updatedPaths = [..._drawingData.paths, completedPath];
      final updatedDrawingData = _drawingData.copyWith(paths: updatedPaths);

      // Update local state first - this is critical to preserve the path
      _drawingData = updatedDrawingData;

      print(
        'Added path to drawing data. Total paths: ${_drawingData.paths.length}',
      );

      // Keep current path until parent confirms the update
      // This prevents the path from being lost during parent rebuild
      final pathToKeep = _currentPath;

      // Notify parent immediately with the updated data
      widget.onDrawingChanged(updatedDrawingData);

      // Clear current path and flag after a delay to ensure parent state is updated
      // This prevents didUpdateWidget from overwriting our local state
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _currentPath == pathToKeep) {
          setState(() {
            _currentPath = null;
            _isProcessingDrawing = false;
          });
        } else if (mounted) {
          // If path changed, just clear the flag
          _isProcessingDrawing = false;
        }
      });
    } else {
      // Clear current path for eraser too
      _currentPath = null;
      setState(() {});
    }
  }

  void _erasePathsAtPoint(Offset point) {
    final eraserRadius = widget.settings.strokeWidth / 2;
    final pathsToKeep = <DrawingPath>[];
    final initialPathCount = _drawingData.paths.length;

    for (final path in _drawingData.paths) {
      bool shouldKeepPath = true;

      // Check if any point in the path is close to the eraser point
      // All coordinates are in canvas local space
      for (final pathPoint in path.points) {
        final distance = (pathPoint.offset - point).distance;
        if (distance <= eraserRadius) {
          // This path is touched by the eraser, remove it completely
          shouldKeepPath = false;
          break;
        }
      }

      // Only keep paths that weren't touched
      if (shouldKeepPath) {
        pathsToKeep.add(path);
      }
    }

    // Only update if paths were actually removed
    if (pathsToKeep.length != initialPathCount) {
      _drawingData = _drawingData.copyWith(paths: pathsToKeep);
      print('Erased paths. Remaining paths: ${pathsToKeep.length}');
      widget.onDrawingChanged(_drawingData);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          // Make background completely transparent
          color: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Drawing surface
              Listener(
                onPointerDown: (event) {
                  _activePointers++;
                  if (_activePointers >= 2) {
                    // Cancel any ongoing drawing when second finger touches
                    if (_currentPath != null) {
                      _currentPath = null;
                    }
                  }
                  setState(() {});
                  _onPointerDown(event);
                },
                onPointerMove: (event) {
                  _onPointerMove(event);
                },
                onPointerUp: (event) {
                  _activePointers = (_activePointers - 1).clamp(0, 10);
                  if (_activePointers < 2) {
                    // If we go back to single pointer, cancel any ongoing path
                    if (_currentPath != null) {
                      _currentPath = null;
                    }
                  }
                  setState(() {});
                  _onPointerUp(event);
                },
                onPointerCancel: (event) {
                  _activePointers = 0;
                  _isApplePencilActive = false;
                  _lastPressure = null;
                  _lastTilt = null;
                  if (_currentPath != null) {
                    _currentPath = null;
                  }
                  setState(() {});
                },
                child: IgnorePointer(
                  ignoring: _shouldPassThrough,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTap: () {
                      // Prevent keyboard from opening when tapping on drawing canvas
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: DrawingPainter(
                            drawingData: _drawingData,
                            currentPath: _currentPath,
                          ),
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          child: Container(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        );
                      },
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

class DrawingPainter extends CustomPainter {
  final DrawingData drawingData;
  final DrawingPath? currentPath;

  DrawingPainter({required this.drawingData, this.currentPath});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed paths
    for (final path in drawingData.paths) {
      _drawPath(canvas, path);
    }

    // Draw current path being drawn
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }
  }

  void _drawPath(Canvas canvas, DrawingPath drawingPath) {
    if (drawingPath.points.isEmpty) return;

    final basePaint = drawingPath.paint;

    // If all points have pressure data, draw with variable stroke width
    final hasPressureData = drawingPath.points.any((p) => p.pressure != null);

    if (hasPressureData && drawingPath.points.length > 1) {
      // Draw with variable stroke width based on pressure
      for (int i = 0; i < drawingPath.points.length - 1; i++) {
        final currentPoint = drawingPath.points[i];
        final nextPoint = drawingPath.points[i + 1];

        // Calculate stroke width based on pressure
        final currentPressure = currentPoint.pressure ?? 0.5;
        final nextPressure = nextPoint.pressure ?? 0.5;
        final avgPressure = (currentPressure + nextPressure) / 2;
        final pressureMultiplier = 0.3 + (avgPressure * 1.2);
        final dynamicStrokeWidth = basePaint.strokeWidth * pressureMultiplier;

        // Create paint with dynamic stroke width
        final dynamicPaint = Paint()
          ..color = basePaint.color
          ..strokeWidth = dynamicStrokeWidth
          ..strokeCap = basePaint.strokeCap
          ..strokeJoin = basePaint.strokeJoin
          ..style = basePaint.style
          ..blendMode = basePaint.blendMode;

        // Draw line segment (all coordinates are in canvas local space)
        final path = Path();
        path.moveTo(currentPoint.offset.dx, currentPoint.offset.dy);
        path.lineTo(nextPoint.offset.dx, nextPoint.offset.dy);
        canvas.drawPath(path, dynamicPaint);
      }

      // Draw individual points for better line quality
      for (final point in drawingPath.points) {
        final pressure = point.pressure ?? 0.5;
        final pressureMultiplier = 0.3 + (pressure * 1.2);
        final dynamicStrokeWidth = basePaint.strokeWidth * pressureMultiplier;

        canvas.drawCircle(
          Offset(point.offset.dx, point.offset.dy),
          dynamicStrokeWidth / 2,
          Paint()
            ..color = basePaint.color
            ..style = PaintingStyle.fill
            ..blendMode = basePaint.blendMode,
        );
      }
    } else {
      // Draw with constant stroke width (no pressure data)
      final path = Path();

      // Move to first point (all coordinates are in canvas local space)
      path.moveTo(
        drawingPath.points.first.offset.dx,
        drawingPath.points.first.offset.dy,
      );

      // Draw lines to subsequent points
      for (int i = 1; i < drawingPath.points.length; i++) {
        final point = drawingPath.points[i];
        path.lineTo(point.offset.dx, point.offset.dy);
      }

      // Draw the path with the original paint
      canvas.drawPath(path, basePaint);

      // Draw individual points for better line quality
      for (final point in drawingPath.points) {
        canvas.drawCircle(
          Offset(point.offset.dx, point.offset.dy),
          basePaint.strokeWidth / 2,
          Paint()
            ..color = basePaint.color
            ..style = PaintingStyle.fill
            ..blendMode = basePaint.blendMode,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.drawingData != drawingData ||
        oldDelegate.currentPath != currentPath;
  }
}
