class NoteFile {
  final String id;
  final String userId;
  final String noteId;
  final String fileUrl;
  final String fileName;
  final String fileType; // 'image' or 'pdf'
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteFile({
    required this.id,
    required this.userId,
    required this.noteId,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating new files (without ID)
  factory NoteFile.create({
    required String userId,
    required String noteId,
    required String fileUrl,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) {
    final now = DateTime.now();
    return NoteFile(
      id: '', // Will be set by database
      userId: userId,
      noteId: noteId,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory NoteFile.fromJson(Map<String, dynamic> json) {
    return NoteFile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      noteId: (json['note_id'] ?? '') as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'note_id': noteId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NoteFile copyWith({
    String? id,
    String? userId,
    String? noteId,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
