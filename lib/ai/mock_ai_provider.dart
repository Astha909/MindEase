import 'ai_provider.dart';

class MockAIProvider implements AIProvider {
  @override
  Future<String> getReply(String message) async {
    await Future.delayed(const Duration(seconds: 1));

    final lower = message.toLowerCase();

    if (lower.contains("anxious")) {
      return "I can sense you're feeling anxious. Let’s slow down together 🫁";
    }

    if (lower.contains("sad")) {
      return "I’m really sorry you're feeling sad 💛";
    }

    if (lower.contains("overwhelmed")) {
      return "That sounds overwhelming. Let’s break it into small steps 🧩";
    }

    return "I’m here with you. Tell me more.";
  }
}
