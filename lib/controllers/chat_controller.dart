import 'package:mindease/ai/ai_service.dart';
import 'package:mindease/ai/mock_ai_provider.dart';

class ChatController {
  late final AIService _aiService;

  ChatController({AIService? aiService}) {
    _aiService = aiService ?? AIService(MockAIProvider());
  }

  Future<String> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      return "";
    }

    return await _aiService.getReply(userMessage);
  }
}
