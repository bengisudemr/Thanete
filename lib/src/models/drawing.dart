import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final double? pressure; // Apple Pencil basınç hassasiyeti (0.0 - 1.0)
  final double? tilt; // Apple Pencil eğim açısı (0.0 - 1.0)

  DrawingPoint({
    required this.offset,
    required this.paint,
    this.pressure,
    this.tilt,
  });

  DrawingPoint copyWith({
    Offset? offset,
    Paint? paint,
    double? pressure,
    double? tilt,
  }) {
    return DrawingPoint(
      offset: offset ?? this.offset,
      paint: paint ?? this.paint,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'paint': {
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'opacity': paint.color.opacity,
      },
      if (pressure != null) 'pressure': pressure,
      if (tilt != null) 'tilt': tilt,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    final offsetData = json['offset'] as Map<String, dynamic>;
    final paintData = json['paint'] as Map<String, dynamic>;
    return DrawingPoint(
      offset: Offset(offsetData['dx'], offsetData['dy']),
      paint: Paint()
        ..color = Color(paintData['color']).withOpacity(paintData['opacity'])
        ..strokeWidth = paintData['strokeWidth']
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
      pressure: json['pressure'] as double?,
      tilt: json['tilt'] as double?,
    );
  }
}

class DrawingPath {
  final List<DrawingPoint> points;
  final Paint paint;
  final String id;

  DrawingPath({required this.points, required this.paint, required this.id});

  DrawingPath copyWith({List<DrawingPoint>? points, Paint? paint, String? id}) {
    return DrawingPath(
      points: points ?? this.points,
      paint: paint ?? this.paint,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'paint': {
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'opacity': paint.color.opacity,
      },
      'id': id,
    };
  }

  factory DrawingPath.fromJson(Map<String, dynamic> json) {
    final paintData = json['paint'] as Map<String, dynamic>;
    return DrawingPath(
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p))
          .toList(),
      paint: Paint()
        ..color = Color(paintData['color']).withOpacity(paintData['opacity'])
        ..strokeWidth = paintData['strokeWidth']
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
      id: json['id'],
    );
  }
}

class DrawingData {
  final List<DrawingPath> paths;
  final Size canvasSize;

  DrawingData({required this.paths, required this.canvasSize});

  DrawingData copyWith({List<DrawingPath>? paths, Size? canvasSize}) {
    return DrawingData(
      paths: paths ?? this.paths,
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }

  bool get isEmpty => paths.isEmpty;
  bool get isNotEmpty => paths.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'paths': paths.map((p) => p.toJson()).toList(),
      'canvasSize': {'width': canvasSize.width, 'height': canvasSize.height},
    };
  }

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    final canvasSizeData = json['canvasSize'] as Map<String, dynamic>;
    return DrawingData(
      paths: (json['paths'] as List)
          .map((p) => DrawingPath.fromJson(p))
          .toList(),
      canvasSize: Size(canvasSizeData['width'], canvasSizeData['height']),
    );
  }
}

enum DrawingTool { pen, highlighter, eraser }

class DrawingSettings {
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final double opacity;

  DrawingSettings({
    this.tool = DrawingTool.pen,
    this.color = Colors.red,
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
  });

  DrawingSettings copyWith({
    DrawingTool? tool,
    Color? color,
    double? strokeWidth,
    double? opacity,
  }) {
    return DrawingSettings(
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
    );
  }

  Paint get paint {
    return Paint()
      ..color = tool == DrawingTool.eraser
          ? Colors.transparent
          : color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = tool == DrawingTool.eraser
          ? BlendMode.clear
          : BlendMode.srcOver;
  }
}
