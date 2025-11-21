import 'package:flutter/material.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/app.dart';
import 'package:thanette/src/screens/chatbot_screen.dart';
import 'package:thanette/src/screens/note_detail_screen.dart';

class FloatingChatbotButton extends StatelessWidget {
  const FloatingChatbotButton({super.key});

  bool _shouldShowButton(String? currentRoute) {
    return currentRoute != ChatbotScreen.route &&
        currentRoute != NoteDetailScreen.route;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ThanetteApp.currentRouteNotifier,
      builder: (context, currentRoute, child) {
        // Check route and hide button when on chatbot screen or note detail screen
        if (!_shouldShowButton(currentRoute)) {
          return const SizedBox.shrink();
        }

        return _buildButton();
      },
    );
  }

  Widget _buildButton() {
    return Positioned(
      bottom: 110,
      right: 9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chatbot name label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AI Asistan',
              style: TextStyle(
                color: const Color.fromARGB(255, 12, 0, 10),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Chatbot button with shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                ...AppTheme.buttonShadow,
                BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'chatbot-button', // Unique hero tag
              onPressed: () {
                ThanetteApp.navigatorKey.currentState?.pushNamed('/chatbot');
              },
              backgroundColor: AppTheme.primaryPink,
              elevation:
                  0, // We handle shadow via container for consistent look
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppTheme.primaryGradient),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
