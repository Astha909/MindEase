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
        _aiService = aiService ??
            AIService(
              GeminiProvider(),
            ),
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

  void clearError() {
    _setError(null);
  }

  String _normalizeMoodWords(
    String input,
  ) {
    String normalized = input.toLowerCase().trim();

    MoodLabels.synonymMap.forEach(
      (key, value) {
        final regex = RegExp(
          r'\b' + key + r'\b',
        );

        normalized = normalized.replaceAll(
          regex,
          value,
        );
      },
    );

    return normalized;
  }

  Future<String> getOrCreateChat(
    String userId,
  ) {
    return _chatService.getOrCreateChat(
      userId,
    );
  }

  Stream<List<Map<String, dynamic>>> listenToMessages(
    String chatId,
  ) {
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
    if (message.trim().isEmpty || isLoading) {
      return;
    }

    _setError(null);

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        userId: userId,
        sender: "user",
        text: message,
      );

      final history = await _chatService.getRecentConversation(
        chatId,
      );

      final normalizedMessage = _normalizeMoodWords(message);

      final localMood = _localClassifier.predict(
        normalizedMessage,
      );

      const highRiskMoods = [
        "overwhelmed",
        "angry",
        "stressed",
      ];

      if (highRiskMoods.contains(
        localMood,
      )) {
        debugPrint(
          "⚠️ High-risk mood detected: "
          "$localMood",
        );
      }

      final emergencyKeywords = _emergencyController.checkEmergencyKeywords(
        normalizedMessage,
      );

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
          text: "I’m really concerned "
              "about what you shared. "
              "You are not alone. "
              "Please contact local "
              "emergency services "
              "immediately or reach "
              "out to a trusted "
              "person nearby.",
        );

        return;
      }

      _setLoading(true);

      final tips = await _wellnessService.getTipsForMood(
        localMood,
      );

      final activity = await _wellnessService.getActivityForMood(
        localMood,
      );

      final memoryPrompt = """
Detected Mood: $localMood

Recent Conversation:
${history.join('\n')}

Suggested Wellness Tips:
${tips.join('\n')}

Suggested Activity:
$activity

User Message:
$normalizedMessage
""";

      Map<String, dynamic> aiResult = {};

      try {
        aiResult = await _aiService
            .getReply(
              message: memoryPrompt,
              detectedMood: localMood,
              tips: tips,
              activity: activity,
            )
            .timeout(
              const Duration(
                seconds: 15,
              ),
            );

        _setError(null);
      } catch (e, stack) {
        debugPrint(
          "AI error: $e",
        );

        debugPrintStack(
          stackTrace: stack,
        );

        aiResult = {
          "chat_reply": "I'm here with you. "
              "Tell me more.",
          "crisis_level": "none",
        };
      }

      final mood = localMood;

      final chatReply = aiResult["chat_reply"]?.toString() ?? "";

      final crisisLevel = aiResult["crisis_level"]?.toString() ?? "none";

      if (crisisLevel == "severe") {
        await _emergencyController.triggerEmergency(
          userId: userId,
          message: message,
          keywordsFound: [
            "ai_severe_detection",
          ],
          triggerType: "ai_severe_detection",
          isConfirmed: true,
        );

        await _chatService.sendMessage(
          chatId: chatId,
          userId: userId,
          sender: "ai",
          text: "I’m really concerned "
              "about what you just "
              "shared. You are not "
              "alone. If you’re in "
              "immediate danger, "
              "please contact local "
              "emergency services "
              "immediately or reach "
              "out to someone "
              "you trust.",
        );

        return;
      }

      try {
        await _wellnessService.addMoodLog(
          userId: userId,
          mood: mood,
          note: activity,
          tips: tips,
        );
      } catch (e) {
        debugPrint(
          "Mood log failed: $e",
        );
      }

      final negativeMoods = [
        "sad",
        "anxious",
        "stressed",
        "overwhelmed",
        "angry",
      ];

      String finalReply = chatReply;

      if (negativeMoods.contains(
            mood,
          ) &&
          tips.isNotEmpty) {
        if (negativeMoods.contains(mood) &&
            tips.isNotEmpty) {

          final firstTip = tips.first;

          if (firstTip is Map<String, dynamic>) {
            finalReply +=
            "\n\n💡 ${firstTip["content"]}";
          } else {
            finalReply +=
            "\n\n💡 $firstTip";
          }
        }
      }

      await _chatService.sendMessage(
        chatId: chatId,
        userId: userId,
        sender: "ai",
        text: finalReply,
        sentiment: mood,
        isCrisis: crisisLevel == "severe",
        crisisLevel: crisisLevel,
      );
    } catch (e, stack) {
      debugPrint(
        "❌ Chat error: $e",
      );

      debugPrintStack(
        stackTrace: stack,
      );

      _setError(
        e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }
}
