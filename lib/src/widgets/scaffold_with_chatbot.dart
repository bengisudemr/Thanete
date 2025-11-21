import 'package:flutter/material.dart';
import 'package:thanette/src/widgets/floating_chat_bubble.dart';

class ScaffoldWithChatbot extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? title;

  const ScaffoldWithChatbot({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          body,
          // Floating chatbot bubble - appears on all screens using this scaffold
          const FloatingChatBubble(),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
