import 'package:cloud_firestore/cloud_firestore.dart';

class WellnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ADD mood log
  Future<void> addMoodLog({
    required String userId,
    required String mood,
    String? note,
  }) async {
    await _firestore.collection('mood_logs').add({
      'userId': userId,
      'mood': mood, // happy, sad, anxious, overwhelmed, frustrated...
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET mood logs (latest first)
  Stream<QuerySnapshot> getMoodLogs(String userId) {
    return _firestore
        .collection('mood_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // GET wellness tips
  Stream<QuerySnapshot> getWellnessTips() {
    return _firestore
        .collection('wellness_tips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
