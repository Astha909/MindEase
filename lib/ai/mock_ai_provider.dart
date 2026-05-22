import 'ai_provider.dart';

class MockAIProvider implements AIProvider {
  @override
  Future<Map<String, dynamic>> getReply({
    required String message,
    required String detectedMood,
    required List<dynamic> tips,
    required String activity,
  }) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    String reply;

    switch (detectedMood) {
      case "anxious":
        reply =
        "I can sense you're feeling anxious. Let’s slow down together 🫁";
        break;

      case "sad":
        reply =
        "I’m really sorry you're feeling sad 💛";
        break;

      case "overwhelmed":
        reply =
        "That sounds overwhelming. Let’s break it into small steps 🧩";
        break;

      case "angry":
        reply =
        "It sounds like you're frustrated right now. Try pausing for a moment.";
        break;

      default:
        reply =
        "I’m here with you. Tell me more.";
    }

    return {
      // classifier is source of truth
      "mood": detectedMood,

      // AI supportive response
      "chat_reply": reply,

      // backend wellness data
      "tips": tips,

      "activity": activity,

      // mock values
      "is_crisis": false,

      "crisis_level": "none",
    };
  }
}