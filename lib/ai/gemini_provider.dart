import 'package:cloud_functions/cloud_functions.dart';
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {

  @override
  Future<Map<String, dynamic>> getReply(String message) async {
    try {

      final callable =
      FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateAIResponse');

      final response = await callable.call({
        "message": message,
      });

      final data = Map<String, dynamic>.from(response.data);

      return {
        "mood": data["mood"] ?? "neutral",
        "chat_reply": data["chat_reply"] ?? "I'm here with you 🤍",
        "tips": data["tips"] ?? [],
        "activity": data["activity"] ?? "",
        "is_crisis": data["is_crisis"] ?? false,
        "crisis_level": data["crisis_level"] ?? "none",
      };

    } catch (e) {
      return {
        "mood": "neutral",
        "chat_reply": "I'm here with you 🤍",
        "tips": [],
        "activity": "",
        "is_crisis": false,
        "crisis_level": "none",
      };
    }
  }
}