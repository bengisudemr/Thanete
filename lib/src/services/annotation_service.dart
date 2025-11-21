import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thanette/src/models/file_annotation.dart';
import 'package:thanette/src/models/note_file.dart';

class AnnotationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload file to Supabase Storage
  Future<NoteFile> uploadFile(
    File file,
    String fileName, {
    required String noteId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileExt = fileName.split('.').last.toLowerCase();
      final filePath =
          '${user.id}/notes/$noteId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload file to storage
      await _supabase.storage
          .from('note-files')
          .uploadBinary(filePath, await file.readAsBytes());

      // Get public URL
      final fileUrl = _supabase.storage
          .from('note-files')
          .getPublicUrl(filePath);

      // Save file metadata to database (id will be auto-generated)
      final response = await _supabase
          .from('note_files')
          .insert({
            'user_id': user.id,
            'note_id': noteId,
            'file_url': fileUrl,
            'file_name': fileName,
            'file_type': _getFileType(fileExt),
            'file_size': await file.length(),
          })
          .select()
          .single();

      return NoteFile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Get annotation for a file
  Future<FileAnnotation?> getAnnotation(String fileId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('file_annotations')
          .select()
          .eq('file_id', fileId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return FileAnnotation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get annotation: $e');
    }
  }

  // Save annotation
  Future<void> saveAnnotation(FileAnnotation annotation) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = annotation.toJson();
      data['user_id'] = user.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('file_annotations').upsert(data);
    } catch (e) {
      throw Exception('Failed to save annotation: $e');
    }
  }

  // Delete annotation
  Future<void> deleteAnnotation(String fileId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('file_annotations')
          .delete()
          .eq('file_id', fileId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete annotation: $e');
    }
  }

  // Get user's files
  Future<List<NoteFile>> getUserFiles() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('note_files')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NoteFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user files: $e');
    }
  }

  // Get files for a specific note
  Future<List<NoteFile>> getNoteFiles(String noteId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('note_files')
          .select()
          .eq('user_id', user.id)
          .eq('note_id', noteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NoteFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get note files: $e');
    }
  }

  // Delete file
  Future<void> deleteFile(String fileId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get file info first
      final fileResponse = await _supabase
          .from('note_files')
          .select()
          .eq('id', fileId)
          .eq('user_id', user.id)
          .single();

      final file = NoteFile.fromJson(fileResponse);

      // Delete from storage - need the relative path inside the bucket
      final filePath = _extractStoragePath(file.fileUrl);
      await _supabase.storage.from('note-files').remove([filePath]);

      // Delete annotation if exists
      await deleteAnnotation(fileId);

      // Delete file record
      await _supabase
          .from('note_files')
          .delete()
          .eq('id', fileId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Convert a public URL to the internal storage path (bucket-relative)
  String _extractStoragePath(String publicUrl) {
    try {
      final uri = Uri.parse(publicUrl);
      // Typical format: /storage/v1/object/public/note-files/{path...}
      final idx = uri.pathSegments.indexOf('note-files');
      if (idx != -1 && idx < uri.pathSegments.length - 1) {
        final parts = uri.pathSegments.sublist(idx + 1);
        return parts.join('/');
      }
      // Fallback: if URL already looks like a path
      if (publicUrl.contains('note-files/')) {
        return publicUrl.split('note-files/').last;
      }
      // As last resort, return the tail (may fail if bucket path missing)
      return publicUrl.split('/').skip(1).join('/');
    } catch (_) {
      // Fallback parsing
      if (publicUrl.contains('note-files/')) {
        return publicUrl.split('note-files/').last;
      }
      return publicUrl;
    }
  }

  // Helper method to determine file type
  String _getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      default:
        return 'document';
    }
  }
}
