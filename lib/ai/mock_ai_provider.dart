import 'ai_provider.dart';

class MockAIProvider implements AIProvider {
  @override
  Future<String> getReply(String message) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return "Thanks for sharing that. It sounds like you’re dealing with a lot. "
        "I’m here with you—do you want to tell me more about what’s been going on?";
  }
}
