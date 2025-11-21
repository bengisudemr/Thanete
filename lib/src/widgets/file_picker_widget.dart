import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thanette/src/models/note_file.dart';
import 'package:thanette/src/services/annotation_service.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(NoteFile) onFileSelected;
  final String noteId;

  const FilePickerWidget({
    Key? key,
    required this.onFileSelected,
    required this.noteId,
  }) : super(key: key);

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  final AnnotationService _annotationService = AnnotationService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dosya Seç',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 20),

          if (_isUploading) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dosya yükleniyor...',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.photo_camera,
                  label: 'Kamera',
                  onTap: _pickFromCamera,
                ),
                _buildOptionButton(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: _pickFromGallery,
                ),
                _buildOptionButton(
                  icon: Icons.description,
                  label: 'Dosya',
                  onTap: _pickFromFiles,
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF7B61FF)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadFile(File(image.path), image.name);
      }
    } catch (e) {
      _showError('Kamera erişimi başarısız: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadFile(File(image.path), image.name);
      }
    } catch (e) {
      _showError('Galeri erişimi başarısız: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        await _uploadFile(file, fileName);
      }
    } catch (e) {
      _showError('Dosya seçimi başarısız: $e');
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final noteFile = await _annotationService.uploadFile(
        file,
        fileName,
        noteId: widget.noteId,
      );

      // Dialog'u kapat
      Navigator.of(context).pop();

      // Callback'i çağır (dialog kapandıktan sonra)
      await Future.delayed(const Duration(milliseconds: 100));
      widget.onFileSelected(noteFile);
    } catch (e) {
      _showError('Dosya yükleme başarısız: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
