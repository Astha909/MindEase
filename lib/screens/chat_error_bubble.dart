import 'package:flutter/material.dart';

class ChatErrorBubble extends StatelessWidget {
  final VoidCallback onRetry;

  const ChatErrorBubble({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Something went wrong 😔"),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                "Retry",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
