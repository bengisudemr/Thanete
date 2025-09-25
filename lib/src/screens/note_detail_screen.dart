import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/editor_provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:thanette/src/models/note.dart';
import 'package:thanette/src/models/drawing.dart';
import 'package:thanette/src/widgets/drawing_canvas.dart';
import 'package:thanette/src/widgets/drawing_toolbar.dart';
import 'package:thanette/src/widgets/color_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class NoteDetailArgs {
  final String? id;
  const NoteDetailArgs({this.id});
}

class NoteDetailScreen extends StatefulWidget {
  static const route = '/note';
  final NoteDetailArgs args;
  const NoteDetailScreen({super.key, required this.args});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String _prevBodySnapshot = '';
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  bool _hasChanges = false;
  bool _isDrawingMode = false;
  DrawingSettings _drawingSettings = DrawingSettings();
  DrawingData _drawingData = DrawingData(paths: [], canvasSize: Size.zero);
  late quill.QuillController _quillController;

  @override
  void initState() {
    super.initState();
    final note = widget.args.id != null
        ? context.read<NotesProvider>().getById(widget.args.id!)
        : null;
    _titleController = TextEditingController(text: note?.title ?? '');
    _bodyController = TextEditingController(text: note?.body ?? '');
    _prevBodySnapshot = _bodyController.text;
    // Initialize quill with existing body as plain text
    _quillController = quill.QuillController(
      document: quill.Document()..insert(0, _bodyController.text),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Initialize drawing data from note
    if (note?.drawingData != null) {
      _drawingData = note!.drawingData!;
    }

    // Listen for changes
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
    _bodyController.addListener(_onBodyChangedForLists);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _bodyController.removeListener(_onTextChanged);
    _bodyController.removeListener(_onBodyChangedForLists);
    _quillController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _onBodyChangedForLists() {
    final editor = context.read<EditorProvider>();
    editor.handleAutoNumberedList(
      _bodyController,
      previousText: _prevBodySnapshot,
    );
    _prevBodySnapshot = _bodyController.text;
  }

  void _save() {
    final id = widget.args.id ?? context.read<NotesProvider>().createNote();
    context.read<NotesProvider>().updateNote(
      id: id,
      title: _titleController.text,
      body: _bodyController.text,
    );

    // Save drawing data if exists
    if (_drawingData.isNotEmpty) {
      context.read<NotesProvider>().updateNoteDrawing(id, _drawingData);
    }

    setState(() {
      _hasChanges = false;
    });
    Navigator.of(context).pop();
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (_isDrawingMode) {
        // Unfocus text fields when entering drawing mode
        _titleFocusNode.unfocus();
        _bodyFocusNode.unfocus();
      }
    });
  }

  void _onDrawingChanged(DrawingData newDrawingData) {
    _drawingData = newDrawingData;
    setState(() {
      _hasChanges = true;
    });
  }

  void _onDrawingSettingsChanged(DrawingSettings newSettings) {
    setState(() {
      _drawingSettings = newSettings;
    });
  }

  void _undoDrawing() {
    if (_drawingData.paths.isNotEmpty) {
      final newPaths = List<DrawingPath>.from(_drawingData.paths);
      newPaths.removeLast();
      _drawingData = _drawingData.copyWith(paths: newPaths);
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _clearDrawing() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çizimi Temizle'),
        content: const Text('Tüm çizimleri silmek istediğinden emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _drawingData = DrawingData(
                paths: [],
                canvasSize: _drawingData.canvasSize,
              );
              setState(() {
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final note = widget.args.id != null
        ? context.read<NotesProvider>().getById(widget.args.id!)
        : null;
    if (note == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        child: ColorPicker(
          selectedColor: note.color,
          onColorChanged: (color) async {
            if (widget.args.id != null) {
              await context.read<NotesProvider>().updateNoteColorRemote(
                id: widget.args.id!,
                color: color,
              );
              setState(() {
                _hasChanges = true;
              });
            }
          },
        ),
      ),
    );
  }

  void _delete() {
    if (widget.args.id != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notu Sil'),
          content: const Text('Bu notu silmek istediğinden emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                context.read<NotesProvider>().deleteNote(widget.args.id!);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close note screen
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  String get _wordCount {
    final text = '${_titleController.text} ${_bodyController.text}';
    final words = text.trim().split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length.toString();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null && widget.args.id != null) {
        await _saveAttachment(image.path, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galeri açılırken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null && widget.args.id != null) {
        await _saveAttachment(image.path, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera açılırken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && widget.args.id != null) {
        final file = result.files.first;
        if (file.path != null) {
          await _saveAttachment(file.path!, file.name);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dosya yolu alınamadı')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _saveAttachment(String sourcePath, String fileName) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Copy file to app directory
      final sourceFile = File(sourcePath);
      final fileExtension = fileName.split('.').last;
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final targetPath = '${attachmentsDir.path}/$uniqueFileName';
      await sourceFile.copy(targetPath);

      // Get file stats
      final fileStat = await sourceFile.stat();

      // Determine attachment type
      AttachmentType type = AttachmentType.other;
      if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif')) {
        type = AttachmentType.image;
      } else if (fileName.toLowerCase().endsWith('.pdf') ||
          fileName.toLowerCase().endsWith('.doc') ||
          fileName.toLowerCase().endsWith('.docx') ||
          fileName.toLowerCase().endsWith('.txt')) {
        type = AttachmentType.document;
      }

      // Create attachment
      final attachment = NoteAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: targetPath,
        type: type,
        size: fileStat.size,
        createdAt: DateTime.now(),
      );

      // Add to note
      context.read<NotesProvider>().addAttachmentToNote(
        widget.args.id!,
        attachment,
      );

      setState(() {
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya eklenirken hata oluştu: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dosya Ekle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),

            // Show gallery option only on mobile platforms
            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid))
              _buildAttachmentOption(
                icon: Icons.photo_library_outlined,
                title: 'Galeriden Seç',
                subtitle: 'Fotoğraf ve resim ekle',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),

            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid))
              const SizedBox(height: 16),

            // Show camera option only on mobile platforms
            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid))
              _buildAttachmentOption(
                icon: Icons.camera_alt_outlined,
                title: 'Fotoğraf Çek',
                subtitle: 'Kamera ile yeni fotoğraf',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),

            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid))
              const SizedBox(height: 16),

            // File picker is available on all platforms
            _buildAttachmentOption(
              icon: Icons.attach_file_outlined,
              title: 'Dosya Seç',
              subtitle: 'Belge, PDF ve diğer dosyalar',
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAttachment(NoteAttachment attachment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttachmentViewerScreen(attachment: attachment),
      ),
    );
  }

  void _deleteAttachment(NoteAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosyayı Sil'),
        content: Text(
          '${attachment.name} dosyasını silmek istediğinden emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().removeAttachmentFromNote(
                widget.args.id!,
                attachment.id,
              );
              // Delete physical file
              File(attachment.path).deleteSync();
              Navigator.pop(context);
              setState(() {
                _hasChanges = true;
              });
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.args.id != null
        ? context.watch<NotesProvider>().getById(widget.args.id!)
        : null;
    final color = note?.color ?? const Color(0xFF7B61FF);
    final isNewNote = widget.args.id == null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        color: const Color(0xFF374151),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Title section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNewNote ? 'Yeni Not' : 'Notu Düzenle',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            isNewNote
                                ? 'Düşüncelerini kaydet'
                                : '$_wordCount kelime',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    // Color picker button
                    if (!isNewNote)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            size: 20,
                            color: color,
                          ),
                          onPressed: _showColorPicker,
                        ),
                      ),

                    if (!isNewNote) const SizedBox(width: 12),

                    // Drawing mode toggle
                    Container(
                      decoration: BoxDecoration(
                        gradient: _isDrawingMode
                            ? const LinearGradient(
                                colors: [Color(0xFFEC60FF), Color(0xFFFF4D79)],
                              )
                            : null,
                        color: _isDrawingMode ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isDrawingMode ? Icons.edit_off : Icons.draw_outlined,
                          size: 20,
                        ),
                        onPressed: _toggleDrawingMode,
                        color: _isDrawingMode
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),

                    const SizedBox(width: 12),

                    if (!isNewNote) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: _delete,
                          color: Colors.red[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Save button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _hasChanges
                              ? [
                                  const Color(0xFFEC60FF),
                                  const Color(0xFFFF4D79),
                                ]
                              : [Colors.grey[300]!, Colors.grey[300]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _hasChanges
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEC60FF,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, size: 20),
                        onPressed: _hasChanges ? _save : null,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Editor area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Color indicator
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                      ),

                      // Title field
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: TextField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Başlık yazın...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            height: 1.2,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) {
                            _bodyFocusNode.requestFocus();
                          },
                        ),
                      ),

                      // Divider
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 1,
                        color: const Color(0xFFF3F4F6),
                      ),

                      // Body field or Drawing area
                      Expanded(
                        child: _isDrawingMode
                            ? Container(
                                margin: const EdgeInsets.all(24),
                                child: DrawingCanvas(
                                  drawingData: _drawingData,
                                  settings: _drawingSettings,
                                  onDrawingChanged: _onDrawingChanged,
                                  isEnabled: true,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    quill.QuillSimpleToolbar(
                                      controller: _quillController,
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFF3F4F6),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: quill.QuillEditor.basic(
                                          controller: _quillController,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // Attachments section
                      if (note != null && note.hasAttachments) ...[
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ekli Dosyalar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...note.attachments.map(
                                (attachment) =>
                                    _buildAttachmentItem(attachment),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Drawing toolbar or regular bottom toolbar
                      if (_isDrawingMode)
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: DrawingToolbar(
                            settings: _drawingSettings,
                            onSettingsChanged: _onDrawingSettingsChanged,
                            onUndo: _undoDrawing,
                            onClear: _clearDrawing,
                            canUndo: _drawingData.paths.isNotEmpty,
                          ),
                        )
                      else
                        // Regular bottom toolbar
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                          child: Row(
                            children: [
                              // Word count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$_wordCount kelime',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Attachment count if any
                              if (note != null && note.hasAttachments)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFEC60FF),
                                        Color(0xFFFF4D79),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.attach_file,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${note.attachmentCount}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Drawing indicator if has drawing
                              if (note != null && note.hasDrawing) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEC60FF,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFEC60FF,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.draw,
                                        size: 12,
                                        color: Color(0xFFEC60FF),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Çizim',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFEC60FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // Attachment button
                              if (widget.args.id != null)
                                _buildFormatButton(
                                  Icons.attach_file_outlined,
                                  'Dosya Ekle',
                                  onTap: _showAttachmentOptions,
                                ),

                              const SizedBox(width: 8),

                              // Format buttons - only show most important ones
                              _buildFormatButton(
                                Icons.format_bold,
                                'Kalın',
                                onTap: () => context
                                    .read<EditorProvider>()
                                    .toggleBold(_bodyController),
                              ),
                              const SizedBox(width: 8),
                              _buildFormatButton(
                                Icons.format_italic,
                                'İtalik',
                                onTap: () => context
                                    .read<EditorProvider>()
                                    .toggleItalic(_bodyController),
                              ),
                              const SizedBox(width: 8),
                              _buildFormatButton(
                                Icons.format_strikethrough,
                                'Üstü Çizili',
                                onTap: () => context
                                    .read<EditorProvider>()
                                    .toggleStrikethrough(_bodyController),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton(
    IconData icon,
    String tooltip, {
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          onPressed:
              onTap ??
              () {
                // TODO: Implement formatting
              },
          color: const Color(0xFF6B7280),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(NoteAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: attachment.type == AttachmentType.image
                  ? Colors.blue[50]
                  : attachment.type == AttachmentType.document
                  ? Colors.green[50]
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              attachment.icon,
              size: 20,
              color: attachment.type == AttachmentType.image
                  ? Colors.blue[600]
                  : attachment.type == AttachmentType.document
                  ? Colors.green[600]
                  : Colors.grey[600],
            ),
          ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${attachment.displaySize} • ${_formatDate(attachment.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                onPressed: () => _viewAttachment(attachment),
                color: const Color(0xFF6B7280),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _deleteAttachment(attachment),
                color: Colors.red[400],
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
}

class AttachmentViewerScreen extends StatelessWidget {
  final NoteAttachment attachment;

  const AttachmentViewerScreen({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          attachment.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Center(
        child: attachment.type == AttachmentType.image
            ? InteractiveViewer(
                child: Image.file(
                  File(attachment.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Dosya yüklenemedi',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              )
            : Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      attachment.icon,
                      size: 64,
                      color: attachment.type == AttachmentType.document
                          ? Colors.green[600]
                          : Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      attachment.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${attachment.displaySize} • ${attachment.type.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement open with external app
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Harici uygulama ile açma özelliği yakında eklenecek',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Harici Uygulamada Aç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC60FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
