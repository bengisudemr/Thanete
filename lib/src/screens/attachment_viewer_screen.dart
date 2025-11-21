import 'package:flutter/material.dart';
import 'package:thanette/src/models/note.dart';
import 'dart:io';

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
      body: Column(
        children: [
          // File info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attachment.displaySize} • ${attachment.type.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: attachment.type == AttachmentType.image
                ? FutureBuilder<bool>(
                    future: File(attachment.path).exists(),
                    builder: (context, snapshot) {
                      final exists = snapshot.data == true;
                      if (!exists) {
                        return const Center(
                          child: Text(
                            'Dosya bulunamadı',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return InteractiveViewer(
                        child: Center(
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
                                    'Resim yüklenemedi',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: attachment.type == AttachmentType.document
                                  ? Colors.green[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    attachment.type == AttachmentType.document
                                    ? Colors.green[200]!
                                    : Colors.grey[200]!,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              attachment.icon,
                              size: 64,
                              color: attachment.type == AttachmentType.document
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            attachment.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${attachment.displaySize} • ${attachment.type.name.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final file = File(attachment.path);
                                  final exists = await file.exists();
                                  if (!exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Dosya bulunamadı'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Harici açma yakında'),
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
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Implement share functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Paylaşma özelliği yakında eklenecek',
                                      ),
                                      backgroundColor: Color(0xFF6B7280),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Paylaş'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(
                                    color: Color(0xFF6B7280),
                                  ),
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
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
