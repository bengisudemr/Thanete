import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/providers/chatbot_provider.dart';
import 'package:thanette/src/providers/notes_provider.dart';

class FloatingChatBubble extends StatefulWidget {
  final String? noteId;
  final String? noteTitle;
  final String? noteContent;
  final String Function()? getCurrentNoteTitle;
  final String Function()? getCurrentNoteContent;
  final Function(String)? onNoteTitleChanged;
  final Function(String)? onNoteContentChanged;
  final Function(String)? onNoteContentAdded;
  final Function(String)? onNoteContentRemoved;
  final Function(String)? onNoteContentRewritten;
  final Function(String)? onNoteTitleAdded;
  final bool isModalOpen;
  final bool hideInFileAnnotation;
  final double extraBottomOffset;
  final Offset? initialOffset;

  const FloatingChatBubble({
    super.key,
    this.noteId,
    this.noteTitle,
    this.noteContent,
    this.getCurrentNoteTitle,
    this.getCurrentNoteContent,
    this.onNoteTitleChanged,
    this.onNoteContentChanged,
    this.onNoteContentAdded,
    this.onNoteContentRemoved,
    this.onNoteContentRewritten,
    this.onNoteTitleAdded,
    this.isModalOpen = false,
    this.hideInFileAnnotation = false,
    this.extraBottomOffset = 0,
    this.initialOffset,
  });

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with TickerProviderStateMixin {
  bool _isMinimized = false;
  late AnimationController _minimizeController;
  late Animation<double> _minimizeAnimation;
  final TextEditingController _messageController = TextEditingController();
  Offset? _bubbleOffset;
  bool _isDragging = false;
  // No persistent scroll controller - use sheet's own controller only

  @override
  void initState() {
    super.initState();

    // Set up animations
    _minimizeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _minimizeAnimation = CurvedAnimation(
      parent: _minimizeController,
      curve: Curves.easeInOut,
    );

    final initialFromProvider = context.read<ChatbotProvider>().bubbleOffset;
    _bubbleOffset = widget.initialOffset ?? initialFromProvider;

    // Set up chatbot callbacks
    final chatbotProvider = context.read<ChatbotProvider>();
    chatbotProvider.onNoteTitleChanged = _onNoteTitleChanged;
    chatbotProvider.onNoteContentChanged = _onNoteContentChanged;
    chatbotProvider.onNoteContentAdded = _onNoteContentAdded;
    chatbotProvider.onNoteContentRemoved = _onNoteContentRemoved;
    chatbotProvider.onNoteContentRewritten = _onNoteContentRewritten;
    chatbotProvider.onNoteTitleAdded = _onNoteTitleAdded;
  }

  // Ensure callbacks are always connected even after rebuilds
  void _setupCallbacks() {
    final chatbotProvider = context.read<ChatbotProvider>();
    chatbotProvider.onNoteTitleChanged = _onNoteTitleChanged;
    chatbotProvider.onNoteContentChanged = _onNoteContentChanged;
    chatbotProvider.onNoteContentAdded = _onNoteContentAdded;
    chatbotProvider.onNoteContentRemoved = _onNoteContentRemoved;
    chatbotProvider.onNoteContentRewritten = _onNoteContentRewritten;
    chatbotProvider.onNoteTitleAdded = _onNoteTitleAdded;
  }

  @override
  void dispose() {
    _minimizeController.dispose();
    _messageController.dispose();
    // no persistent controller to dispose
    super.dispose();
  }

  void _onNoteTitleChanged(String newTitle) {
    if (widget.onNoteTitleChanged != null) {
      widget.onNoteTitleChanged!(newTitle);
    }
    _minimizeBubble();
  }

  void _onNoteContentChanged(String newContent) {
    if (widget.onNoteContentChanged != null) {
      widget.onNoteContentChanged!(newContent);
    }
    _minimizeBubble();
  }

  void _onNoteContentAdded(String addContent) {
    if (widget.onNoteContentAdded != null) {
      widget.onNoteContentAdded!(addContent);
    }
    _minimizeBubble();
  }

  void _onNoteContentRemoved(String removeContent) {
    if (widget.onNoteContentRemoved != null) {
      widget.onNoteContentRemoved!(removeContent);
    }
    _minimizeBubble();
  }

  void _onNoteContentRewritten(String rewriteContent) {
    if (widget.onNoteContentRewritten != null) {
      widget.onNoteContentRewritten!(rewriteContent);
    }
    _minimizeBubble();
  }

  void _onNoteTitleAdded(String addTitle) {
    if (widget.onNoteTitleAdded != null) {
      widget.onNoteTitleAdded!(addTitle);
    }
    _minimizeBubble();
  }

  void _minimizeBubble() {
    setState(() {
      _isMinimized = true;
    });
    _minimizeController.forward();

    // Show success message (only if ScaffoldMessenger exists)
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Not güncellendi!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Auto-expand after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isMinimized = false;
        });
        _minimizeController.reverse();
      }
    });
  }

  void _openBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) {
        final inset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final height = MediaQuery.of(sheetContext).size.height * 0.85;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: inset > 0 ? inset : 0),
          child: CupertinoPopupSurface(
            isSurfacePainted: true,
            child: SizedBox(
              height: height,
              child: _buildExpandedView(
                navigatorContext: sheetContext,
                bottomInset: inset,
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatbotProvider = context.read<ChatbotProvider>();
    final notesProvider = context.read<NotesProvider>();

    if (widget.noteId != null) {
      final dynamicTitle = widget.getCurrentNoteTitle != null
          ? widget.getCurrentNoteTitle!()
          : widget.noteTitle;
      final dynamicContent = widget.getCurrentNoteContent != null
          ? widget.getCurrentNoteContent!()
          : widget.noteContent;
      chatbotProvider.sendMessageWithNoteContext(
        text,
        notesProvider,
        noteId: widget.noteId!,
        noteTitle: dynamicTitle,
        noteContent: dynamicContent,
      );
    } else {
      chatbotProvider.sendMessage(text, notesProvider);
    }

    _messageController.clear();

    // Auto-scroll handled by DraggableScrollableSheet's controller
    // No manual scrolling needed - the sheet manages its own scroll
  }

  @override
  Widget build(BuildContext context) {
    // Set up callbacks on every build to ensure they're always connected
    _setupCallbacks();

    final theme = Theme.of(context);
    final bubbleIconColor = theme.colorScheme.onPrimary;
    final chatbotProvider = context.watch<ChatbotProvider>();

    // Hide bubble when modal is open or in file annotation screen
    if (widget.isModalOpen || widget.hideInFileAnnotation) {
      return const SizedBox.shrink();
    }

    final mq = MediaQuery.of(context);
    final viewInsets = mq.viewInsets.bottom;

    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;

    Offset resolvedOffset =
        _bubbleOffset ??
        chatbotProvider.bubbleOffset ??
        Offset(screenWidth - 72, screenHeight * 0.62);
    if (_bubbleOffset == null) {
      resolvedOffset = Offset(screenWidth - 72, screenHeight * 0.62);
    } else if (!_isDragging) {
      resolvedOffset = Offset(
        _bubbleOffset!.dx,
        viewInsets > 0
            ? (_bubbleOffset!.dy.clamp(0.0, screenHeight - viewInsets - 80))
            : _bubbleOffset!.dy,
      );
    }
    final maxX = screenWidth - 60;
    final maxY = viewInsets > 0
        ? (screenHeight - viewInsets - 80)
        : (screenHeight - 60);
    resolvedOffset = Offset(
      resolvedOffset.dx.clamp(0.0, maxX),
      resolvedOffset.dy.clamp(0.0, maxY),
    );
    _bubbleOffset = resolvedOffset;
    if (chatbotProvider.bubbleOffset != resolvedOffset && !_isDragging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChatbotProvider>().setBubbleOffset(resolvedOffset);
        }
      });
    }

    // Reserve a small top area; bottom sheet will handle height constraints

    // Keep previous calculations removed; bottom sheet manages its own size

    return Positioned(
      left: resolvedOffset.dx,
      top: resolvedOffset.dy,
      child: AnimatedBuilder(
        animation: _minimizeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isMinimized ? 0.8 : 1.0,
            child: GestureDetector(
              onPanStart: (_) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                final updated = _bubbleOffset! + details.delta;
                final newX = updated.dx.clamp(0.0, maxX);
                final newY = updated.dy.clamp(0.0, maxY);
                setState(() {
                  _bubbleOffset = Offset(newX, newY);
                });
                context.read<ChatbotProvider>().setBubbleOffset(
                  Offset(newX, newY),
                );
              },
              onPanEnd: (_) {
                setState(() {
                  _isDragging = false;
                });
                final offset = _bubbleOffset;
                if (offset != null) {
                  context.read<ChatbotProvider>().setBubbleOffset(offset);
                }
              },
              child: SizedBox(
                width: 60,
                height: 60,
                child: _buildMinimizedView(bubbleIconColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinimizedView(Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (_isDragging) return;
        _openBottomSheet();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: AppTheme.primaryGradient),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.auto_awesome, color: iconColor, size: 28),
      ),
    );
  }

  Widget _buildExpandedView({
    required BuildContext navigatorContext,
    double bottomInset = 0,
  }) {
    final mq = MediaQuery.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryPink.withOpacity(0.15),
                child: Icon(
                  CupertinoIcons.sparkles,
                  color: AppTheme.primaryPink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Asistan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(navigatorContext).pop(),
                child: const Icon(CupertinoIcons.xmark, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<ChatbotProvider>(
            builder: (context, chatbotProvider, child) {
              final messages = chatbotProvider.messages;

              if (messages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Merhaba! Notunuz hakkında nasıl yardımcı olabilirim?',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return CupertinoScrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                ),
              );
            },
          ),
        ),
        Consumer<ChatbotProvider>(
          builder: (context, chatbotProvider, child) {
            if (!chatbotProvider.isLoading) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: const [
                  CupertinoActivityIndicator(radius: 10),
                  SizedBox(width: 8),
                  Text(
                    'Düşünüyorum...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            bottomInset > 0 ? bottomInset : mq.padding.bottom + 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _messageController,
                  placeholder: 'Mesajınızı yazın...',
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onPressed: _sendMessage,
                child: const Icon(
                  CupertinoIcons.arrow_up_circle_fill,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryPink,
              child: const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryPink
                    : AppTheme.backgroundTertiary,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.3,
                  decoration: TextDecoration.none,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.backgroundTertiary,
              child: const Icon(
                CupertinoIcons.person,
                color: AppTheme.textSecondary,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
