import 'package:flutter/material.dart';

/// Persistent floating action button, present above every tab/route -
/// the Flipkart-style chat bubble. Wrapping AppShell in this (rather than
/// putting it inside each page) means it survives tab switches and keeps
/// its own state once the real AI Assistance feature replaces the
/// placeholder onTap below.
class ChatAssistantOverlay extends StatelessWidget {
  const ChatAssistantOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: isMobile ? 70 : 16,
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Sargam Coming Soon ...")));
            },
            icon: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6EC), // Background color
                shape: BoxShape.circle, // Or remove for a square
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/chat_assistant_icon.png',
                height: 80,
                width: 80,
                cacheHeight: 90,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
