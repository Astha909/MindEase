import 'package:flutter/material.dart';
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
        _emergencyController = emergencyController ?? EmergencyController(),
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

  Future<String> getOrCreateChat(String userId) {
    return _chatService.getOrCreateChat(userId);
  }

  Stream listenToMessages(String chatId) {
    return _chatService.listenToMessages(chatId);
  }

  /*String? detectMood(String message) {
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
  } */

  Future<void> handleMessage({
    required String chatId,
    required String userId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      // Save user message
      await _chatService.sendMessage(
        chatId: chatId,
        sender: "user",
        text: message,
      );

// 🧠 Get structured AI response from Cohere
      final aiResult = await _aiService.getReply(message);

      final mood = aiResult["mood"]?.toString() ?? "neutral";
      final chatReply = aiResult["chat_reply"]?.toString() ?? "";
      final tips = aiResult["tips"] as List<dynamic>? ?? [];
      final activity = aiResult["activity"]?.toString() ?? "";
      final crisisLevel = aiResult["crisis_level"]?.toString() ?? "none";

// 🚨 Severe-only escalation
      if (crisisLevel == "severe") {
        await _emergencyController.triggerEmergency(
          userId: userId,
          message: message,
          keywordsFound: ["ai_severe_detection"],
          triggerType: "ai_severe_detection",
        );

        await _chatService.sendMessage(
          chatId: chatId,
          sender: "ai",
          text: "I’m really concerned about what you just shared. "
              "You are not alone. If you’re in immediate danger, "
              "please contact local emergency services right now "
              "or reach out to someone you trust.",
        );

        return;
      }

// 💾 Save mood to Wellness system (always)
      await _wellnessService.addMoodLog(
        userId: userId,
        mood: mood,
        note: activity,
        tips: tips,
      );

// 🔴 Option 2: Show tip only if mood is negative
      final negativeMoods = [
        "sad",
        "anxious",
        "stressed",
        "overwhelmed",
        "angry"
      ];

      String finalReply = chatReply;

      if (negativeMoods.contains(mood) && tips.isNotEmpty) {
        finalReply += "\n\n💡 ${tips.first}";
      }

// 📤 Send final AI reply to chat
      await _chatService.sendMessage(
        chatId: chatId,
        sender: "ai",
        text: finalReply,
      );
    } catch (e) {
      _setError("Failed to process message");
    } finally {
      _setLoading(false);
    }
  }
}
