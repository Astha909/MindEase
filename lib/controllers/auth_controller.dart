import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();

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

  /// REGISTER
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? sexuality,
  }) async {
    _setLoading(true);
    _setError(null);

    User? user;

    try {
      user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception("Registration failed");
      }

      await _profileService.createUserProfile(
        name: name,
        age: age,
        gender: gender,
        sexuality: sexuality,
      );

      return user;
    } catch (e) {
      if (user != null) {
        await user.delete(); // rollback
      }
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// LOGIN (SAFE)
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception("Login failed");
      }

      final profileExists =
      await _profileService.doesUserProfileExist();

      if (!profileExists) {
        await _authService.logout();
        throw Exception("Profile missing. Please register again.");
      }

      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
