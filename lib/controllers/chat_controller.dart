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

  Stream<List<Map<String, dynamic>>> listenToMessages(String chatId) {
    return _chatService.listenToMessages(chatId);
  }

  Future<List<Map<String, dynamic>>> fetchMessages({
    required String chatId,
    dynamic lastDocument,
    int limit = 20,
  }) async {
    final snapshot = await _chatService.fetchMessages(
      chatId: chatId,
      lastDocument: lastDocument,
      limit: limit,
    );

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newText,
  }) {
    return _chatService.editMessage(
      chatId: chatId,
      messageId: messageId,
      userId: userId,
      newText: newText,
    );
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) {
    return _chatService.deleteMessage(
      chatId: chatId,
      messageId: messageId,
      userId: userId,
    );
  }

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
        userId: userId,
        sender: "user",
        text: message,
      );

// 🧠 Get structured AI response from Cohere
      Map<String, dynamic> aiResult = {};

      try {
        aiResult = await _aiService.getReply(message);
      } catch (e) {
        debugPrint("AI error: $e");
        aiResult = {
          "mood": "neutral",
          "chat_reply": "I'm here with you. Tell me more.",
          "tips": [],
          "activity": "",
          "crisis_level": "none"
        };
      }

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
          isConfirmed: true,
        );

        await _chatService.sendMessage(
          chatId: chatId,
          userId: userId,
          sender: "ai",
          text: "I’m really concerned about what you just shared. "
              "You are not alone. If you’re in immediate danger, "
              "please contact local emergency services right now "
              "or reach out to someone you trust.",
        );

        return;
      }

// 💾 Save mood to Wellness system (always)
      // 💾 Save mood to Wellness system (non-blocking)
      try {
        await _wellnessService.addMoodLog(
          userId: userId,
          mood: mood,
          note: activity,
          tips: tips,
        );
      } catch (e) {
        // Do NOT break chat if mood logging fails
        debugPrint("Mood log failed: $e");
      }

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
        userId: userId,
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
