import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final UserProfileService _profileService = UserProfileService();

  Stream<String?> get authUserIdStream => _authService.authUserIdStream;

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

  String? getCurrentUserId() {
    return _authService.currentUser?.uid;
  }

  // REGISTER
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? sexuality,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception(
          "Registration failed",
        );
      }

      await _profileService.createUserProfile(
        user: user,
        name: name,
        age: age,
        gender: gender,
        sexuality: sexuality,
      );

      return true;
    } catch (e) {
      // Rollback auth state
      try {
        await _authService.logout();
      } catch (_) {}

      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // LOGIN
  Future<bool> login({
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
        throw Exception(
          "Login failed",
        );
      }

      final profileExists = await _profileService.doesUserProfileExist(
        user,
      );

      if (!profileExists) {
        await _authService.logout();

        throw Exception(
          "Profile missing. Please register again.",
        );
      }

      return true;
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // GOOGLE LOGIN
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        throw Exception(
          "Google sign-in cancelled",
        );
      }

      final profileExists = await _profileService.doesUserProfileExist(
        user,
      );

      if (!profileExists) {
        // Prevent orphan auth session
        await _authService.logout();

        throw Exception(
          "Profile missing. Please register again.",
        );
      }

      return true;
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // PASSWORD RESET
  Future<bool> resetPassword(
    String email,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendPasswordReset(
        email.trim(),
      );

      return true;
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // SEND VERIFICATION EMAIL
  Future<bool> sendVerificationEmail() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendVerificationEmail();

      return true;
    } catch (e) {
      _setError(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      _setLoading(true);
      _setError(null);

      await _authService.logout();
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
}
