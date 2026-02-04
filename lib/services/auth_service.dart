import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER + CREATE FIRESTORE PROFILE
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? sexuality,
  }) async {
    try {
      // 1. Create Firebase Auth user
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;

      // 2. Create Firestore user profile
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'sexuality': sexuality ?? '',
        'profilePic': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential =
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
