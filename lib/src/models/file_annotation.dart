import 'package:flutter/material.dart';

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final DateTime timestamp;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
    required this.timestamp,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: json['stroke_width'] as double,
      opacity: json['opacity'] as double? ?? 1.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'stroke_width': strokeWidth,
      'opacity': opacity,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TextNote {
  final String id;
  final String text;
  final Offset position;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  TextNote({
    required this.id,
    required this.text,
    required this.position,
    this.backgroundColor = const Color(0xFFFFF3CD),
    this.textColor = const Color(0xFF856404),
    this.fontSize = 14.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TextNote.fromJson(Map<String, dynamic> json) {
    return TextNote(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Offset(
        json['position_x'] as double,
        json['position_y'] as double,
      ),
      backgroundColor: Color(json['background_color'] as int),
      textColor: Color(json['text_color'] as int),
      fontSize: json['font_size'] as double,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'position_x': position.dx,
      'position_y': position.dy,
      'background_color': backgroundColor.value,
      'text_color': textColor.value,
      'font_size': fontSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TextNote copyWith({
    String? id,
    String? text,
    Offset? position,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TextNote(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FileAnnotation {
  final String id;
  final String fileId;
  final String userId;
  final List<DrawingStroke> drawingStrokes;
  final List<TextNote> textNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileAnnotation({
    required this.id,
    required this.fileId,
    required this.userId,
    this.drawingStrokes = const [],
    this.textNotes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileAnnotation.fromJson(Map<String, dynamic> json) {
    return FileAnnotation(
      id: json['id'] as String,
      fileId: json['file_id'] as String,
      userId: json['user_id'] as String,
      drawingStrokes: (json['drawing_strokes'] as List? ?? [])
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      textNotes: (json['text_notes'] as List? ?? [])
          .map((t) => TextNote.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_id': fileId,
      'user_id': userId,
      'drawing_strokes': drawingStrokes.map((s) => s.toJson()).toList(),
      'text_notes': textNotes.map((t) => t.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FileAnnotation copyWith({
    String? id,
    String? fileId,
    String? userId,
    List<DrawingStroke>? drawingStrokes,
    List<TextNote>? textNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileAnnotation(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      userId: userId ?? this.userId,
      drawingStrokes: drawingStrokes ?? this.drawingStrokes,
      textNotes: textNotes ?? this.textNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
