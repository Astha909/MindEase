import 'dart:ui';
import 'package:flutter/material.dart';

class ChatErrorBubble extends StatelessWidget {
  final VoidCallback onRetry;

  const ChatErrorBubble({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 4,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 6,
              sigmaY: 6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.red.shade50.withOpacity(0.9),
                border: Border.all(
                  color: Colors.red.shade100,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Something went wrong 😔",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      "Dismiss",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
