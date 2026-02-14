import 'package:cloud_firestore/cloud_firestore.dart';
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
  Stream<QuerySnapshot> getMoodLogs(String userId) {
    return _wellnessService.getMoodLogs(userId);
  }

  Stream<QuerySnapshot> getWellnessTips() {
    return _wellnessService.getWellnessTips();
  }

  Future<String?> getLatestMood(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first.data()['mood'];
  }


  Future<void> addMood({
    required String userId,
    required String mood,
    String? note,
    bool isManual = true,
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
