import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ADD emergency contact
  Future<void> addEmergencyContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    await _firestore.collection('emergency_contacts').add({
      'userId': userId,
      'name': name,
      'phone': phone,
      'relation': relation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET emergency contacts
  Stream<QuerySnapshot> getEmergencyContacts(String userId) {
    return _firestore
        .collection('emergency_contacts')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // DELETE emergency contact
  Future<void> deleteEmergencyContact(String contactId) async {
    await _firestore
        .collection('emergency_contacts')
        .doc(contactId)
        .delete();
  }

  // 🔥 CHECK emergency keywords
  bool isEmergencyMessage(String message) {
    final keywords = [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      'hurt myself',
      'overdose',
      'cutting',
      'no reason to live',
      'jump off',
      'hopeless',
    ];

    final lowerMessage = message.toLowerCase();

    for (final word in keywords) {
      if (lowerMessage.contains(word)) {
        return true;
      }
    }
    return false;
  }

  // 🔥 SAVE emergency log
  Future<void> saveEmergencyLog({
    required String userId,
    required String triggerType,
    required String detectedText,
    required List<String> keywordsFound,
  }) async {
    await _firestore.collection('emergency_logs').add({
      'userId': userId,
      'triggerType': triggerType,
      'detectedText': detectedText,
      'keywordsFound': keywordsFound,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
