import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

class EmergencyController extends ChangeNotifier {
  final EmergencyService _emergencyService = EmergencyService();

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

  Future<void> addContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _emergencyService.addEmergencyContact(
        userId: userId,
        name: name,
        phone: phone,
        relation: relation,
      );
    } catch (e) {
      _setError("Failed to add emergency contact");
    } finally {
      _setLoading(false);
    }
  }
}
