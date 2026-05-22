// ignore_for_file: avoid_print

import 'package:cloud_functions/cloud_functions.dart';

import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  @override
  Future<Map<String, dynamic>> getReply({
    required String message,
    required String detectedMood,
    required List<dynamic> tips,
    required String activity,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'generateAIResponse',
      );

      final response = await callable.call({
        "message": message,
        "mood": detectedMood,
        "tips": tips,
        "activity": activity,
      }).timeout(
        const Duration(seconds: 12),
      );

      if (response.data == null) {
        throw Exception(
          "Empty AI response",
        );
      }

      if (response.data is! Map) {
        throw Exception(
          "Invalid AI response format",
        );
      }

      final data = Map<String, dynamic>.from(
        response.data,
      );

      return {
        // CLASSIFIER is source of truth
        "mood": detectedMood,

        // AI supportive response
        "chat_reply": data["chat_reply"]?.toString() ?? "I'm here with you.",

        // Backend wellness tips
        "tips": tips,

        // Backend activity suggestion
        "activity": activity,

        // AI crisis flags only
        "is_crisis": data["is_crisis"] == true,

        "crisis_level": data["crisis_level"]?.toString() ?? "none",
      };
    } catch (e, stack) {
      print(
        "❌ Gemini error: $e",
      );

      print(stack);

      throw Exception(
        "AI response unavailable right now",
      );
    }
  }
}
