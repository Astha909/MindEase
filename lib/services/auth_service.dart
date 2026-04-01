import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


bool _isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  Stream<String?> get authUserIdStream =>
      _auth.idTokenChanges().map((user) => user?.uid);

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
      final User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      return user;

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
      final User? user = userCredential.user;

      if (user != null) {
        await user.reload(); // 🔥 Force refresh
        final refreshedUser = _auth.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          await _auth.signOut();
          throw Exception("Please verify your email before logging in.");
        }
      }

      return user;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  // PASSWORD RESET
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw Exception("Email is required");
    }

    if (!_isValidEmail(email)) {
      throw Exception("Invalid email format");
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Password reset failed");
    }
  }


// GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signOut(); // 🔥 force account picker

      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Google Sign-In failed");
    }
  }


  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

// SEND VERIFICATION EMAIL AGAIN
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    if (user.emailVerified) {
      throw Exception("Email already verified");
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Failed to send verification email");
    }
  }


}
