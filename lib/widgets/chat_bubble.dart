import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8,
              sigmaY: 8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7B61FF).withOpacity(0.95),
                          const Color(0xFF5B8CFF).withOpacity(0.92),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.72),
                          Colors.white.withOpacity(0.40),
                        ],
                      ),
                border: Border.all(
                  color: isUser
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? Colors.deepPurple.withOpacity(0.20)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final animatedBubble = bubble
        .animate()
        .fade(
          duration: 250.ms,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 250.ms,
        )
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
          duration: 250.ms,
        );

    if (isUser) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: animatedBubble,
      );
    }

    return animatedBubble;
  }
}
