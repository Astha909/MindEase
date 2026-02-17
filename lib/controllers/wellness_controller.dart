import 'package:flutter/material.dart';
import '../services/wellness_service.dart';
import '../ai/ai_service.dart';
import '../ai/cohere_provider.dart';

class WellnessController extends ChangeNotifier {
  final WellnessService _wellnessService = WellnessService();
  final AIService _aiService = AIService(CohereProvider());

  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  Stream getMoodLogs(String userId) {
    return _wellnessService.getMoodLogs(userId);
  }

  Stream getWellnessTips() {
    return _wellnessService.getWellnessTips();
  }

  Future<void> analyzeManualMood({
    required String userId,
    required String moodInput,
  }) async {
    if (moodInput.trim().isEmpty) {
      _setError("Mood input cannot be empty");
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final aiResult = await _aiService.getReply("User feels: $moodInput");

      // SAFETY: ensure proper type handling
      String mood = moodInput;
      List<dynamic> tips = [];
      String activity = "";

      mood = aiResult["mood"]?.toString() ?? moodInput;
      tips = aiResult["tips"] is List ? aiResult["tips"] : [];
      activity = aiResult["activity"]?.toString() ?? "";

      await _wellnessService.deleteLatestMood(userId);


      await _wellnessService.addMoodLog(
        userId: userId,
        mood: mood,
        note: activity,
        tips: tips,
      );
    } catch (e) {
      _setError("Failed to analyze mood");
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getLatestMood(String userId) async {
    try {
      return await _wellnessService.fetchLatestMood(userId);
    } catch (e) {
      _setError("Failed to fetch latest mood");
      return null;
    }
  }


  Future<void> addMood({
    required String userId,
    required String mood,
    String? note,
    bool isManual = true,
  }) async {
    if (mood.trim().isEmpty) {
      _setError("Mood cannot be empty");
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _wellnessService.addMoodLog(
        userId: userId,
        mood: mood,
        note: note ?? "",
      );
    } catch (e) {
      _setError("Failed to add mood");
    } finally {
      _setLoading(false);
    }
  }
}
