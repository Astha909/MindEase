import 'package:mindease/services/chat_service.dart';
import 'package:mindease/controllers/emergency_controller.dart';
import 'package:mindease/ai/ai_service.dart';
import 'package:mindease/ai/mock_ai_provider.dart';

class ChatController {
  final ChatService _chatService;
  final EmergencyController _emergencyController;
  final AIService _aiService;

  ChatController({
    ChatService? chatService,
    EmergencyController? emergencyController,
    AIService? aiService,
  })  : _chatService = chatService ?? ChatService(),
        _emergencyController =
            emergencyController ?? EmergencyController(),
        _aiService = aiService ?? AIService(MockAIProvider());

  Future<void> handleMessage({
    required String userId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    final chatId = await _chatService.getOrCreateChat(userId);

    // Save user message
    await _chatService.sendMessage(
      chatId: chatId,
      sender: "user",
      text: message,
    );

    // 🔍 Check emergency via controller
    final detectedKeywords =
    _emergencyController.checkEmergencyKeywords(message);

    if (detectedKeywords.isNotEmpty) {
      await _emergencyController.triggerEmergency(
        userId: userId,
        message: message,
        keywordsFound: detectedKeywords,
      );

      await _chatService.sendMessage(
        chatId: chatId,
        sender: "ai",
        text:
        "I’m really concerned about what you just shared. "
            "You are not alone. If you’re in immediate danger, "
            "please contact local emergency services right now "
            "or reach out to someone you trust.",
      );

      return;
    }

    // Normal AI flow
    final aiReply = await _aiService.getReply(message);

    await _chatService.sendMessage(
      chatId: chatId,
      sender: "ai",
      text: aiReply,
    );
  }
}
