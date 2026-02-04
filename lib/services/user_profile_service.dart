import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': user.email,
      'age': age,
      'gender': gender,
      'sexuality': sexuality ?? '',
      'profilePic': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
