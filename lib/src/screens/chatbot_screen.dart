import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/chatbot_provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/widgets/ui/ui_primitives.dart';

class ChatbotScreen extends StatefulWidget {
  static const route = '/chatbot';

  final String? noteId;
  final String? noteTitle;
  final String? noteContent;

  const ChatbotScreen({
    super.key,
    this.noteId,
    this.noteTitle,
    this.noteContent,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(onPressed: onTap, label: label);
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXXL,
        vertical: AppTheme.spacingL,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Text(
            'Düşünüyorum...',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXXL,
        AppTheme.spacingXL,
        AppTheme.spacingXXL,
        AppTheme.spacingXXXL,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmitted,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
        child: SurfaceCard(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          borderColor: Colors.transparent,
          borderWidth: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
                    child: Icon(
                      isUser ? Icons.person : Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    isUser ? 'Sen' : 'thanette AI',
                    style: AppTheme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(message.text, style: AppTheme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Set up callbacks for note editing
    final chatbotProvider = context.read<ChatbotProvider>();
    chatbotProvider.onNoteTitleChanged = _onNoteTitleChanged;
    chatbotProvider.onNoteContentChanged = _onNoteContentChanged;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNoteTitleChanged(String newTitle) {
    // This will be handled by the parent widget (NoteDetailScreen)
    // We need to pass this back through the modal
    if (mounted) {
      Navigator.of(context).pop({'action': 'title_changed', 'value': newTitle});
    }
  }

  void _onNoteContentChanged(String newContent) {
    // This will be handled by the parent widget (NoteDetailScreen)
    if (mounted) {
      Navigator.of(
        context,
      ).pop({'action': 'content_changed', 'value': newContent});
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatbotProvider = context.read<ChatbotProvider>();
    final notesProvider = context.read<NotesProvider>();

    // If we have note context, include it
    if (widget.noteId != null) {
      chatbotProvider.sendMessageWithNoteContext(
        text,
        notesProvider,
        noteId: widget.noteId!,
        noteTitle: widget.noteTitle,
        noteContent: widget.noteContent,
      );
    } else {
      chatbotProvider.sendMessage(text, notesProvider);
    }

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = context.watch<ChatbotProvider>();
    final messages = chatbotProvider.messages;

    return AppScaffold(
      padded: false,
      title: 'AI Asistan',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Sohbeti Temizle',
          onPressed: chatbotProvider.clearMessages,
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          if (chatbotProvider.isLoading) const _ThinkingIndicator(),
          _ChatInputBar(
            controller: _messageController,
            isSubmitting: chatbotProvider.isLoading,
            onSubmitted: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXXL,
        vertical: AppTheme.spacingXXXL,
      ),
      child: EmptyState(
        title: 'AI asistanın hazır',
        message:
            'Notların hakkında soru sorabilir, özet isteyebilir veya düzenleme yardımı alabilirsin.',
        icon: Icons.auto_awesome,
        primaryAction: Column(
          children: [
            _SuggestionButton(
              label: 'Notlarımı nasıl kategorize ederim?',
              onTap: () {
                _messageController.text = 'Notlarımı nasıl kategorize ederim?';
                _sendMessage();
              },
            ),
            const SizedBox(height: AppTheme.spacingS),
            _SuggestionButton(
              label: 'Bugünkü yapılacaklarımı hatırlat.',
              onTap: () {
                _messageController.text = 'Bugünkü yapılacaklarımı hatırlat.';
                _sendMessage();
              },
            ),
            const SizedBox(height: AppTheme.spacingS),
            _SuggestionButton(
              label: 'Yeni bir not başlatmama yardım et.',
              onTap: () {
                _messageController.text = 'Yeni bir not başlatmama yardım et.';
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
