import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/widgets/todo_list_widget.dart';

enum AttachmentType { image, document, other }

class NoteAttachment {
  final String id;
  final String name;
  final String path;
  final AttachmentType type;
  final int size;
  final DateTime createdAt;

  NoteAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.createdAt,
  });

  String get displaySize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.document:
        return Icons.description_outlined;
      case AttachmentType.other:
        return Icons.attach_file_outlined;
    }
  }
}

class NoteModel {
  final String id;
  String title;
  String body;
  Color color;
  bool isPinned;
  String category;
  final List<NoteAttachment> attachments;
  DrawingData? drawingData;
  String? appleDrawingData;
  List<TodoItem> todos;

  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    this.isPinned = false,
    this.category = 'general',
    List<NoteAttachment>? attachments,
    this.drawingData,
    List<TodoItem>? todos,
  }) : attachments = attachments ?? [],
       todos = todos ?? [];

  String get preview {
    if (body.isEmpty) return '';
    try {
      final parsed = jsonDecode(body);
      if (parsed is List) {
        final buffer = StringBuffer();
        for (final op in parsed) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString();
      }
    } catch (_) {
      // Ignore parse errors and fall back to raw text
    }
    return body;
  }

  void addAttachment(NoteAttachment attachment) {
    attachments.add(attachment);
  }

  void removeAttachment(String attachmentId) {
    attachments.removeWhere((a) => a.id == attachmentId);
  }

  void updateDrawing(DrawingData? drawing) {
    drawingData = drawing;
  }

  void updateAppleDrawing(String? appleDrawing) {
    appleDrawingData = appleDrawing;
  }

  bool get hasAttachments => attachments.isNotEmpty;
  int get attachmentCount => attachments.length;
  bool get hasDrawing => drawingData != null && drawingData!.isNotEmpty;

  NoteModel copyWith({
    String? id,
    String? title,
    String? body,
    Color? color,
    bool? isPinned,
    String? category,
    List<NoteAttachment>? attachments,
    DrawingData? drawingData,
    String? appleDrawingData,
    List<TodoItem>? todos,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
      drawingData: drawingData ?? this.drawingData,
      todos: todos ?? this.todos,
    )..appleDrawingData = appleDrawingData ?? this.appleDrawingData;
  }
}
