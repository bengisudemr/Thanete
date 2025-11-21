import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:thanette/src/providers/enhanced_annotation_provider.dart';
import 'package:thanette/src/models/file_annotation.dart';
import 'package:thanette/src/widgets/enhanced_annotation_toolbar.dart';

class EnhancedAnnotationPainter extends CustomPainter {
  final List<DrawingStroke> allStrokes;
  final List<DrawingStroke> currentStrokes;
  final List<ShapeAnnotation> shapes;
  final List<TextNote> textNotes;
  final List<AnnotationLayer> layers;
  final int activeLayerIndex;

  EnhancedAnnotationPainter({
    required this.allStrokes,
    required this.currentStrokes,
    required this.shapes,
    required this.textNotes,
    required this.layers,
    required this.activeLayerIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint strokes
    _paintStrokes(canvas, allStrokes);
    _paintStrokes(canvas, currentStrokes);

    // Paint shapes
    _paintShapes(canvas, shapes);
    // Text notes are rendered via widgets (EnhancedTextNoteWidget) in the
    // screen layer for interactivity (drag, edit, delete). Avoid painting
    // them here to prevent duplicate overlay (e.g., yellow background ghost
    // text at top-left).
  }

  void _paintStrokes(Canvas canvas, List<DrawingStroke> strokes) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final currentPoint = stroke.points[i];
        // final previousPoint = stroke.points[i - 1];

        // Use quadratic bezier for smoother lines
        if (i < stroke.points.length - 1) {
          final nextPoint = stroke.points[i + 1];
          final controlPoint = Offset(
            (currentPoint.dx + nextPoint.dx) / 2,
            (currentPoint.dy + nextPoint.dy) / 2,
          );
          path.quadraticBezierTo(
            currentPoint.dx,
            currentPoint.dy,
            controlPoint.dx,
            controlPoint.dy,
          );
        } else {
          path.lineTo(currentPoint.dx, currentPoint.dy);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _paintShapes(Canvas canvas, List<ShapeAnnotation> shapes) {
    for (final shape in shapes) {
      final paint = Paint()
        ..color = shape.color
        ..strokeWidth = shape.strokeWidth
        ..style = PaintingStyle.stroke;

      switch (shape.type) {
        case ShapeType.rectangle:
          _paintRectangle(canvas, shape, paint);
          break;
        case ShapeType.circle:
          _paintCircle(canvas, shape, paint);
          break;
        case ShapeType.line:
          _paintLine(canvas, shape, paint);
          break;
        case ShapeType.arrow:
          _paintArrow(canvas, shape, paint);
          break;
        case ShapeType.highlight:
          _paintHighlight(canvas, shape, paint);
          break;
      }
    }
  }

  void _paintRectangle(Canvas canvas, ShapeAnnotation shape, Paint paint) {
    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);
    canvas.drawRect(rect, paint);
  }

  void _paintCircle(Canvas canvas, ShapeAnnotation shape, Paint paint) {
    final center = Offset(
      (shape.startPoint.dx + shape.endPoint.dx) / 2,
      (shape.startPoint.dy + shape.endPoint.dy) / 2,
    );
    final radius = (shape.endPoint - shape.startPoint).distance / 2;
    canvas.drawCircle(center, radius, paint);
  }

  void _paintLine(Canvas canvas, ShapeAnnotation shape, Paint paint) {
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);
  }

  void _paintArrow(Canvas canvas, ShapeAnnotation shape, Paint paint) {
    // Draw main line
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);

    // Draw arrowhead
    final direction = (shape.endPoint - shape.startPoint).normalized();
    final arrowLength = shape.strokeWidth * 3;
    final arrowAngle = 0.5; // radians

    final arrowPoint1 =
        shape.endPoint -
        Offset(
          direction.dx * arrowLength * math.cos(arrowAngle) +
              direction.dy * arrowLength * math.sin(arrowAngle),
          direction.dy * arrowLength * math.cos(arrowAngle) -
              direction.dx * arrowLength * math.sin(arrowAngle),
        );

    final arrowPoint2 =
        shape.endPoint -
        Offset(
          direction.dx * arrowLength * math.cos(-arrowAngle) +
              direction.dy * arrowLength * math.sin(-arrowAngle),
          direction.dy * arrowLength * math.cos(-arrowAngle) -
              direction.dx * arrowLength * math.sin(-arrowAngle),
        );

    canvas.drawLine(shape.endPoint, arrowPoint1, paint);
    canvas.drawLine(shape.endPoint, arrowPoint2, paint);
  }

  void _paintHighlight(Canvas canvas, ShapeAnnotation shape, Paint paint) {
    paint.style = PaintingStyle.fill;
    paint.color = paint.color.withOpacity(0.3);

    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);
    canvas.drawRect(rect, paint);
  }

  // Removed text note painting; see comment in paint().

  @override
  bool shouldRepaint(EnhancedAnnotationPainter oldDelegate) {
    return allStrokes != oldDelegate.allStrokes ||
        currentStrokes != oldDelegate.currentStrokes ||
        shapes != oldDelegate.shapes ||
        textNotes != oldDelegate.textNotes ||
        layers != oldDelegate.layers ||
        activeLayerIndex != oldDelegate.activeLayerIndex;
  }
}

// Helper extension for Offset
extension OffsetExtension on Offset {
  Offset normalized() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return Offset(dx / length, dy / length);
  }
}

// Helper functions for trigonometry
double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);
