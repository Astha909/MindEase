import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Widget bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        constraints: const BoxConstraints(
          maxWidth: 250,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [
                    Color(0xff4facfe),
                    Color(0xff00f2fe),
                  ],
                )
              : const LinearGradient(
                  colors: [
                    Color(0xffe0e0e0),
                    Color(0xffcfcfcf),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );

    if (isUser) {
      bubble = GestureDetector(
        onLongPress: onLongPress,
        child: bubble,
      );
    }

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: bubble,
    );
  }
}
