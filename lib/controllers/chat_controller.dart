import 'package:flutter/material.dart';
import 'package:mindease/services/chat_service.dart';
import 'package:mindease/controllers/emergency_controller.dart';
import 'package:mindease/ai/ai_service.dart';
import 'package:mindease/services/wellness_service.dart';
import 'package:mindease/services/mood_classifier.dart';
import '../utils/mood_labels.dart';
import '../ai/gemini_provider.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  final EmergencyController _emergencyController;
  final AIService _aiService;
  final WellnessService _wellnessService;
  final MoodClassifier _localClassifier = MoodClassifier();

  bool isLoading = false;
  String? errorMessage;

  ChatController({
    ChatService? chatService,
    EmergencyController? emergencyController,
    AIService? aiService,
    WellnessService? wellnessService,
  })  : _chatService = chatService ?? ChatService(),
        _emergencyController = emergencyController ?? EmergencyController(),
        _aiService = aiService ?? AIService(GeminiProvider()),
        _wellnessService = wellnessService ?? WellnessService() {
          _initLocalClassifier();
        }

  Future<void> _initLocalClassifier() async {
    await _localClassifier.loadModel();
  }


  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  String _normalizeMoodWords(String input) {
    String normalized = input.toLowerCase().trim();

    MoodLabels.synonymMap.forEach((key, value) {
      final regex = RegExp(r'\b' + key + r'\b');
      normalized = normalized.replaceAll(regex, value);
    });

    return normalized;
  }
  Future<String> getOrCreateChat(String userId) {
    return _chatService.getOrCreateChat(userId);
  }

  Stream<List<Map<String, dynamic>>> listenToMessages(String chatId) {
    return _chatService.listenToMessages(chatId);
  }

  Future<List<Map<String, dynamic>>> fetchMessages({
    required String chatId,
    Map<String, dynamic>? lastMessage,
    int limit = 20,
  }) async {
    final snapshot = await _chatService.fetchMessages(
      chatId: chatId,
      lastMessage: lastMessage,
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

      // Fetch prior conversation BEFORE saving current turn
      final history =
      await _chatService.getRecentConversation(chatId);

      // Save current user message
      await _chatService.sendMessage(
        chatId: chatId,
        userId: userId,
        sender: "user",
        text: message,
      );

      Map<String, dynamic> aiResult = {};


      final normalizedMessage = _normalizeMoodWords(message);
      final localMood = _localClassifier.predict(normalizedMessage);
      // 🧠 Rule-based pre-decision (classifier integration FIX)
      const highRiskMoods = ["overwhelmed", "angry", "stressed"];

      if (highRiskMoods.contains(localMood)) {
        debugPrint("⚠️ High-risk mood detected: $localMood");
      }
      // 🚨 Local emergency pre-check before AI
      final emergencyKeywords = _emergencyController.checkEmergencyKeywords(normalizedMessage);

      if (emergencyKeywords.isNotEmpty) {
        await _emergencyController.triggerEmergency(
          userId: userId,
          message: message,
          keywordsFound: emergencyKeywords,
          triggerType: "local_keyword_detection",
          isConfirmed: true,
        );

        await _chatService.sendMessage(
          chatId: chatId,
          userId: userId,
          sender: "ai",
          text: "I’m really concerned about what you shared. You are not alone. "
              "Please contact local emergency services right now or reach out to a trusted person nearby.",
        );

        return;
      }
      try {

        final memoryPrompt = """
        Recent conversation:
        ${history.join('\n')}
        
        Current user message:
        $normalizedMessage
        
        Detected mood:
        $localMood
        """;
        aiResult = await _aiService.getReply(memoryPrompt);
      } catch (e){
        debugPrint("AI error: $e");
        aiResult = {
          "chat_reply": "I'm here with you. Tell me more.",
          "crisis_level": "none"
        };
      }

      final mood = localMood;

      final chatReply =
          aiResult["chat_reply"]?.toString() ?? "";

      final crisisLevel =
          aiResult["crisis_level"]?.toString() ?? "none";

// 📚 Tips & activities from WellnessService
      final tips =
      await _wellnessService.getTipsForMood(mood);

      final activity =
      await _wellnessService.getActivityForMood(mood);


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
        sentiment: mood,
        isCrisis: crisisLevel == "severe",
        crisisLevel: crisisLevel,
      );
    } catch (e) {
      _setError("Failed to process message");
    } finally {
      _setLoading(false);
    }
  }
}
