import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// CREATE PROFILE
  Future<void> createUserProfile({
    required String name,
    required int age,
    required String gender,
    String? sexuality,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    if (name.trim().isEmpty) {
      throw Exception("Name cannot be empty");
    }

    if (age <= 0) {
      throw Exception("Invalid age");
    }

    if (gender.trim().isEmpty) {
      throw Exception("Gender required");
    }

    final doc = _firestore.collection('users').doc(user.uid);

    final snapshot = await doc.get();
    if (snapshot.exists) {
      throw Exception("Profile already exists");
    }

    await doc.set({
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'age': age,
      'gender': gender,
      'sexuality': sexuality ?? '',
      'profilePic': '',
      'moodLevel': null,
      'overwhelmed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// CHECK PROFILE EXISTS
  Future<bool> doesUserProfileExist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
    await _firestore.collection('users').doc(user.uid).get();
    return doc.exists;
  }

  /// FETCH PROFILE
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final doc =
    await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      throw Exception("Profile not found");
    }

    return doc.data()!;
  }
}
