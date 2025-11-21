import 'package:flutter/material.dart';
import 'package:thanette/src/models/file_annotation.dart';

class AnnotationPainter extends CustomPainter {
  final List<DrawingStroke> allStrokes;
  final List<DrawingStroke> currentStrokes;

  AnnotationPainter({required this.allStrokes, required this.currentStrokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Paint all completed strokes
    for (final stroke in allStrokes) {
      _paintStroke(canvas, stroke);
    }

    // Paint current drawing strokes
    for (final stroke in currentStrokes) {
      _paintStroke(canvas, stroke);
    }
  }

  void _paintStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.allStrokes != allStrokes ||
        oldDelegate.currentStrokes != currentStrokes;
  }
}
