import 'dart:ui';
import 'package:flutter/material.dart';

class AITypingLoader extends StatelessWidget {
  const AITypingLoader({super.key});

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
          maxWidth: MediaQuery.of(context).size.width * 0.72,
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
                color: Colors.white.withOpacity(0.55),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
              child: const Text(
                "Chhotu is typing...",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
