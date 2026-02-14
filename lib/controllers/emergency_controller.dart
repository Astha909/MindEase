import 'package:cloud_firestore/cloud_firestore.dart';
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
  Stream<QuerySnapshot> getEmergencyContacts(String userId) {
    return _emergencyService.getEmergencyContacts(userId);
  }

  /// 🔍 Check for emergency keywords
  List<String> checkEmergencyKeywords(String message) {
    return _emergencyService.getEmergencyKeywords(message);
  }

  /// 🚨 Trigger full emergency flow
  Future<void> triggerEmergency({
    required String userId,
    required String message,
    required List<String> keywordsFound,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _emergencyService.triggerEmergency(
        userId: userId,
        message: message,
        keywordsFound: keywordsFound,
      );
    }catch (e) {
      print("EMERGENCY ERROR: $e");
      _setError("Emergency process failed");
    }
    finally {
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
  Future<void> deleteContact(String contactId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _emergencyService.deleteEmergencyContact(contactId);
    } catch (e) {
      _setError("Failed to delete contact");
    } finally {
      _setLoading(false);
    }
  }

}
