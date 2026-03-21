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

  Stream getEmergencyContacts(String userId) {
    return _emergencyService.getEmergencyContacts(userId);
  }

  /// 🔍 Check for emergency keywords
  List<String> checkEmergencyKeywords(String message) {
    if (message.trim().isEmpty) return [];
    return _emergencyService.getEmergencyKeywords(message);
  }

  /// 🚨 Trigger full emergency flow
  Future<void> triggerEmergency({
    required String userId,
    required String message,
    required List<String> keywordsFound,
    required bool isConfirmed,
    String triggerType = "keyword_detection",
  }) async {
    if (message.trim().isEmpty || keywordsFound.isEmpty) {
      _setError("Invalid emergency trigger");
      return;
    }
    if (!isConfirmed) {
      _setError("Emergency not confirmed");
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _emergencyService.triggerEmergency(
        userId: userId,
        message: message,
        keywordsFound: keywordsFound,
        triggerType: triggerType,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// ➕ Add contact
  Future<void> addContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        relation.trim().isEmpty) {
      _setError("All fields are required");
      return;
    }

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
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteContact(String contactId) async {
    if (contactId.trim().isEmpty) {
      _setError("Invalid contact");
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _emergencyService.deleteEmergencyContact(contactId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
