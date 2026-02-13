import 'package:mindease/services/chat_service.dart';
import 'package:mindease/services/emergency_service.dart';
import 'package:mindease/ai/ai_service.dart';
import 'package:mindease/ai/mock_ai_provider.dart';

class ChatController {
  final ChatService _chatService;
  final EmergencyService _emergencyService;
  final AIService _aiService;

  /// Flexible constructor
  ChatController({
    ChatService? chatService,
    EmergencyService? emergencyService,
    AIService? aiService,
  })  : _chatService = chatService ?? ChatService(),
        _emergencyService = emergencyService ?? EmergencyService(),
        _aiService = aiService ?? AIService(MockAIProvider());

  Future<void> handleMessage({
    required String userId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    // 1️⃣ Get or create chat
    final chatId = await _chatService.getOrCreateChat(userId);

    // 2️⃣ Save user message
    await _chatService.sendMessage(
      chatId: chatId,
      sender: "user",
      text: message,
    );

    // 3️⃣ Check emergency
    if (_emergencyService.isEmergencyMessage(message)) {
      await _emergencyService.saveEmergencyLog(
        userId: userId,
        triggerType: "keyword",
        detectedText: message,
        keywordsFound: [],
      );
    }

    // 4️⃣ Get AI reply
    final aiReply = await _aiService.getReply(message);

    // 5️⃣ Save AI reply
    await _chatService.sendMessage(
      chatId: chatId,
      sender: "ai",
      text: aiReply,
    );
  }
}
