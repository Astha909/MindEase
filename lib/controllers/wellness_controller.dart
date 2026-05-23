import 'package:flutter/material.dart';

import '../services/wellness_service.dart';
import '../services/mood_classifier.dart';
import '../services/notification_service.dart';

import '../ai/ai_service.dart';
import '../ai/gemini_provider.dart';

class WellnessController extends ChangeNotifier {
  final WellnessService _wellnessService = WellnessService();

  final NotificationService _notificationService = NotificationService();

  final AIService _aiService = AIService(
    GeminiProvider(),
  );

  final MoodClassifier _localClassifier = MoodClassifier();

  WellnessController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _localClassifier.loadModel();

    await _notificationService.init();

    await _wellnessService.seedSampleTips();
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

  Stream getMoodLogs(
    String userId,
  ) {
    return _wellnessService.getMoodLogs(userId);
  }

  Stream getWellnessTips() {
    return _wellnessService.getWellnessTips();
  }

  // ANALYZE MANUAL MOOD
  // ANALYZE MANUAL MOOD
  Future<void> analyzeManualMood({
    required String userId,
    required String moodInput,
  }) async {
    if (moodInput.trim().isEmpty) {
      _setError(
        "Mood input cannot be empty",
      );

      return;
    }

    _setLoading(true);

    _setError(null);

    try {
      final localMood = _localClassifier.predict(
        moodInput,
      );

      final tips = await _wellnessService.getTipsForMood(
        localMood,
      );

      final activity = await _wellnessService.getActivityForMood(
        localMood,
      );

      final aiResult = await _aiService
          .getReply(
            message: "User feels: "
                "$moodInput",
            detectedMood: localMood,
            tips: tips,
            activity: activity,
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      String mood = localMood;

      final aiMood = aiResult["mood"]?.toString();

      mood = (aiMood == null || aiMood.isEmpty || aiMood == "neutral")
          ? localMood
          : aiMood;

      await _wellnessService.addMoodLog(
        userId: userId,
        mood: mood,
        note: activity,
        tips: tips,
      );

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getLatestMood(
    String userId,
  ) async {
    try {
      return await _wellnessService.fetchLatestMood(
        userId,
      );
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return null;
    }
  }

  Future<Map<String, int>> getWeeklyMoodStats(
    String userId,
  ) {
    return _wellnessService.getWeeklyMoodStats(
      userId,
    );
  }

  Future<Map<String, int>> getMonthlyMoodStats(
    String userId,
  ) {
    return _wellnessService.getMonthlyMoodStats(
      userId,
    );
  }

  Future<List<Map<String, dynamic>>> getMoodTrendData(
    String userId,
  ) {
    return _wellnessService.getMoodTrendData(
      userId,
    );
  }

  Future<void> saveReminder({
    required String userId,
    required String time,
    required bool enabled,
  }) async {
    try {
      await _wellnessService.saveReminder(
        userId: userId,
        time: time,
        enabled: enabled,
      );

      if (enabled) {
        await _notificationService
            .showDailyReminder(
          id: 1,
          title: 'Daily Check-In',
          body:
          'How are you feeling today?',
        );
      } else {
        await _notificationService
            .cancelReminder(1);
      }

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }
  }

  Future<void> restoreReminder(
      String userId,
      ) async {
    try {
      final reminder =
      await _wellnessService
          .getReminder(userId);

      if (reminder == null) {
        return;
      }

      final enabled =
          reminder['enabled'] ?? false;

      if (enabled) {
        await _notificationService
            .showDailyReminder(
          id: 1,
          title: 'Daily Check-In',
          body:
          'How are you feeling today?',
        );
      }

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> getReminder(
    String userId,
  ) {
    return _wellnessService.getReminder(
      userId,
    );
  }

  Future<void> addMood({
    required String userId,
    required String mood,
    String? note,
    bool isManual = true,
  }) async {
    if (mood.trim().isEmpty) {
      _setError(
        "Mood cannot be empty",
      );

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

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    } finally {
      _setLoading(false);
    }
  }

  // DELETE LATEST MOOD
  Future<void> deleteLatestMood(
    String userId,
  ) async {
    try {
      await _wellnessService.deleteLatestMood(
        userId,
      );

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    }
  }

  Future<void> sendDailyCheckInReminder() async {
    try {
      await _notificationService.showDailyReminder(
        id: 1,
        title: 'Daily Check-In',
        body: 'How are you feeling today?',
      );

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );
    }
  }

  Future<void> cancelReminder() async {
    try {
      await _notificationService
          .cancelReminder(1);

      _setError(null);
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }
  }
}
