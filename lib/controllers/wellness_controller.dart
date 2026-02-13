import 'package:flutter/material.dart';
import '../services/wellness_service.dart';

class WellnessController extends ChangeNotifier {
  final WellnessService _wellnessService = WellnessService();

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

  Future<void> addMood({
    required String userId,
    required String mood,
    String? note,
  }) async {
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
