import 'package:flutter/material.dart';
import 'package:thanette/src/models/drawing.dart';

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
  final List<NoteAttachment> attachments;
  DrawingData? drawingData;

  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    this.isPinned = false,
    List<NoteAttachment>? attachments,
    this.drawingData,
  }) : attachments = attachments ?? [];

  String get preview => body.isEmpty ? ' ' : body;

  void addAttachment(NoteAttachment attachment) {
    attachments.add(attachment);
  }

  void removeAttachment(String attachmentId) {
    attachments.removeWhere((a) => a.id == attachmentId);
  }

  void updateDrawing(DrawingData? drawing) {
    drawingData = drawing;
  }

  bool get hasAttachments => attachments.isNotEmpty;
  int get attachmentCount => attachments.length;
  bool get hasDrawing => drawingData != null && drawingData!.isNotEmpty;
}
