import 'package:flutter/material.dart';
import '../services/wellness_service.dart';
import '../services/mood_classifier.dart';
import '../ai/ai_service.dart';
import '../ai/cohere_provider.dart';

class WellnessController extends ChangeNotifier {
  final WellnessService _wellnessService = WellnessService();
  final AIService _aiService = AIService(CohereProvider());
  final MoodClassifier _localClassifier = MoodClassifier();
  WellnessController() {
    _initLocalClassifier();
  }
  Future<void> _initLocalClassifier() async {
    await _localClassifier.loadModel();
  }

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
      final localMood = _localClassifier.predict(moodInput);

      final aiResult = await _aiService.getReply(
          "User feels: $moodInput (detected mood: $localMood)"
      );

      // SAFETY: ensure proper type handling
      String mood = moodInput;
      List<dynamic> tips = [];
      String activity = "";

      mood = aiResult["mood"]?.toString() ?? localMood;
      tips = aiResult["tips"] is List ? aiResult["tips"] : [];
      activity = aiResult["activity"]?.toString() ?? "";

      await _wellnessService.addMoodLog(
        userId: userId,
        mood: mood,
        note: activity,
        tips: tips,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getLatestMood(String userId) async {
    try {
      return await _wellnessService.fetchLatestMood(userId);
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ FIXED: NOW INSIDE CLASS
  Future<void> deleteLatestMood(String userId) async {
    try {
      await _wellnessService.deleteLatestMood(userId);
    } catch (e) {
      _setError(e.toString());
    }
  }
}
