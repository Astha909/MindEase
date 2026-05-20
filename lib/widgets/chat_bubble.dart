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
    return Align(
      alignment:
      isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          constraints: BoxConstraints(
            maxWidth:
            MediaQuery.of(context).size.width *
                0.78,
          ),
          decoration: BoxDecoration(
            color:
            isUser
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.15),
            borderRadius:
            BorderRadius.circular(22),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}