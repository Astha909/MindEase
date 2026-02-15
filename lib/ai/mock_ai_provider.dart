import 'ai_provider.dart';

class MockAIProvider implements AIProvider {
  @override
  Future<Map<String, dynamic>> getReply(String message) async {
    await Future.delayed(const Duration(seconds: 1));

    final lower = message.toLowerCase();

    if (lower.contains("anxious")) {
      return {
        "mood": "anxious",
        "chat_reply": "I can sense you're feeling anxious. Let’s slow down together 🫁",
        "tips": [],
        "activity": ""
      };
    }

    if (lower.contains("sad")) {
      return {
        "mood": "sad",
        "chat_reply": "I’m really sorry you're feeling sad 💛",
        "tips": [],
        "activity": ""
      };
    }

    if (lower.contains("overwhelmed")) {
      return {
        "mood": "overwhelmed",
        "chat_reply": "That sounds overwhelming. Let’s break it into small steps 🧩",
        "tips": [],
        "activity": ""
      };
    }

    return {
      "mood": "neutral",
      "chat_reply": "I’m here with you. Tell me more.",
      "tips": [],
      "activity": ""
    };
  }
}
