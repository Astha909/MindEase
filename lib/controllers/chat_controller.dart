import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindease/services/chat_service.dart';
import 'package:mindease/controllers/emergency_controller.dart';
import 'package:mindease/ai/ai_service.dart';
import 'package:mindease/services/wellness_service.dart';
import '../ai/cohere_provider.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  final EmergencyController _emergencyController;
  final AIService _aiService;
  final WellnessService _wellnessService;

  bool isLoading = false;
  String? errorMessage;

  ChatController({
    ChatService? chatService,
    EmergencyController? emergencyController,
    AIService? aiService,
    WellnessService? wellnessService,
  })  : _chatService = chatService ?? ChatService(),
        _emergencyController =
            emergencyController ?? EmergencyController(),
        _aiService = aiService ?? AIService(CohereProvider()),
        _wellnessService = wellnessService ?? WellnessService();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  Stream<QuerySnapshot> listenToMessages(String chatId) {
    return _chatService.listenToMessages(chatId);
  }

  String? detectMood(String message) {
    final text = message.toLowerCase();

    if (text.contains("anxious") || text.contains("nervous")) {
      return "anxiety";
    }

    if (text.contains("sad") ||
        text.contains("low") ||
        text.contains("depressed")) {
      return "self-care";
    }

    if (text.contains("stressed") ||
        text.contains("overwhelmed")) {
      return "stress";
    }

    return null;
  }

  Future<void> handleMessage({
    required String userId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final chatId = await _chatService.getOrCreateChat(userId);

      // Save user message
      await _chatService.sendMessage(
        chatId: chatId,
        sender: "user",
        text: message,
      );

      // 🔍 Emergency Check
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

      // 🔍 Detect mood
      final detectedCategory = detectMood(message);

      if (detectedCategory != null) {
        await _wellnessService.addMoodLog(
          userId: userId,
          mood: detectedCategory,
        );
      }

      // Normal AI flow
      String aiReply = await _aiService.getReply(message);

      if (detectedCategory != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('wellness_tips')
            .where('category', isEqualTo: detectedCategory)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final tip = snapshot.docs.first.data()['content'];
          aiReply += "\n\n💡 Small suggestion: $tip";
        }
      }

      await _chatService.sendMessage(
        chatId: chatId,
        sender: "ai",
        text: aiReply,
      );
    } catch (e) {
      _setError("Failed to process message");
    } finally {
      _setLoading(false);
    }
  }
}
