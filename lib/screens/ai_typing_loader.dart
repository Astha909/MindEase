import 'package:flutter/material.dart';

class AITypingLoader extends StatelessWidget {
  const AITypingLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "AI is typing...",
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
