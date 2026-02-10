import 'package:firebase_auth/firebase_auth.dart';

bool _isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // REGISTER (AUTH ONLY)
  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      throw Exception("Email cannot be empty");
    }

    if (!_isValidEmail(email)) {
      throw Exception("Invalid email format");
    }

    if (password.isEmpty) {
      throw Exception("Password cannot be empty");
    }

    if (password.length < 6) {
      throw Exception("Password must be at least 6 characters");
    }

    try {
      final userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Registration failed");
    }
  }

  // LOGIN
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception("Email and password required");
    }

    try {
      final userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
