import 'package:cloud_functions/cloud_functions.dart';

import 'ai_provider.dart';

class GeminiProvider implements AIProvider {

  @override
  Future<Map<String, dynamic>> getReply(
      String message,
      ) async {

    try {

      final callable =
      FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'generateAIResponse',
      );

      final response =
      await callable.call({

        "message": message,

      }).timeout(
        const Duration(seconds: 20),
      );

      if (response.data == null) {

        throw Exception(
            "Empty AI response");
      }

      final data =
      Map<String, dynamic>.from(
          response.data);

      return {

        "mood":
        data["mood"]?.toString() ??
            "neutral",

        "chat_reply":
        data["chat_reply"]
            ?.toString() ??
            "I'm here with you.",

        "tips":
        data["tips"] is List
            ? data["tips"]
            : [],

        "activity":
        data["activity"]
            ?.toString() ??
            "",

        "is_crisis":
        data["is_crisis"] == true,

        "crisis_level":
        data["crisis_level"]
            ?.toString() ??
            "none",
      };

    } catch (e, stack) {

      print("❌ Gemini error: $e");

      print(stack);

      return {

        "mood": "neutral",

        "chat_reply":
        "I'm here with you.",

        "tips": [],

        "activity": "",

        "is_crisis": false,

        "crisis_level": "none",
      };
    }
  }
}