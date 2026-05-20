import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';

class ProfileController extends ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Map<String, dynamic>? userProfile;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  /// FETCH PROFILE
  Future<void> fetchProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      userProfile = await _profileService.getUserProfile();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// UPDATE PROFILE
  Future<void> updateProfile({
    required String name,
    required int age,
    required String gender,
    String? sexuality,
  }) async {
    if (name.trim().isEmpty || age <= 0 || gender.trim().isEmpty) {
      _setError("Invalid profile data");
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _profileService.updateUserProfile(
        name: name,
        age: age,
        gender: gender,
        sexuality: sexuality,
      );

      // Refresh profile manually without re-triggering loading state
      userProfile = await _profileService.getUserProfile();
      notifyListeners();
    } catch (e) {
      _setError("Failed to update profile");
    } finally {
      _setLoading(false);
    }
  }

  /// DELETE ACCOUNT
  Future<void> deleteAccount() async {
    _setLoading(true);
    _setError(null);

    try {
      await _profileService.deleteUserProfile();
      userProfile = null;
    } catch (e) {
      _setError("Failed to delete account");
    } finally {
      _setLoading(false);
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.logout();
      userProfile = null; // clear cached profile
    } catch (e) {
      _setError("Logout failed");
    } finally {
      _setLoading(false);
    }
  }
}
