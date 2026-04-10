// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';




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
  List<String> getEmergencyKeywords(String message) {
    if (message.trim().isEmpty) return [];

    final lowerMessage = message.toLowerCase().trim();

    final directPhrases = [
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
      'i am dying',
      'im dying',
      "i'm dying",
      'die today',
      'want to kill myself',
      'dont want to live',
      "don't want to live",
      'i want to disappear',
      'i cant go on',
      "i can't go on",
    ];

    final found = <String>[];

    for (final phrase in directPhrases) {
      if (lowerMessage.contains(phrase)) {
        found.add(phrase);
      }
    }

    final severePatterns = [
      RegExp(r'\bi\s+am\s+dying\b'),
      RegExp(r"\bi'?m\s+dying\b"),
      RegExp(r'\bi\s+want\s+to\s+die\b'),
      RegExp(r'\bi\s+want\s+to\s+kill\s+myself\b'),
      RegExp(r'\bi\s+do\s+not\s+want\s+to\s+live\b'),
      RegExp(r"\bi\s+don't\s+want\s+to\s+live\b"),
      RegExp(r'\bi\s+cant\s+go\s+on\b'),
      RegExp(r"\bi\s+can't\s+go\s+on\b"),
      RegExp(r'\bkill\s+myself\b'),
      RegExp(r'\bend\s+my\s+life\b'),
      RegExp(r'\bhurt\s+myself\b'),
      RegExp(r'\boverdose\b'),
      RegExp(r'\bcut\s+myself\b'),
      RegExp(r'\bno\s+reason\s+to\s+live\b'),
    ];

    for (final pattern in severePatterns) {
      final match = pattern.firstMatch(lowerMessage);
      if (match != null) {
        final matchedText = match.group(0);
        if (matchedText != null && !found.contains(matchedText)) {
          found.add(matchedText);
        }
      }
    }

    return found;
  }


  // 🔥 SAVE emergency log
  Future<void> saveEmergencyLog({
    required String userId,
    required String triggerType,
    required String detectedText,
    required List<String> keywordsFound,
    int contactsNotified = 0,
  }) async {
    await _firestore.collection('emergency_logs').add({
      'userId': userId,
      'triggerType': triggerType,
      'detectedText': detectedText,
      'keywordsFound': keywordsFound,
      'contactsNotified': contactsNotified,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getEmergencyLogs(String userId) {
    return _firestore
        .collection('emergency_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  // 🚨 TRIGGER EMERGENCY FLOW
  // 🚨 TRIGGER EMERGENCY FLOW
  Future<void> triggerEmergency({
    required String userId,
    required String message,
    required List<String> keywordsFound,
    String triggerType = "keyword_detection",
  }) async {
    // 1️⃣ Check last emergency log for cooldown
    int notifiedCount = 0;
    final recentLogs = await _firestore
        .collection('emergency_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (recentLogs.docs.isNotEmpty) {
      final lastLog = recentLogs.docs.first.data();
      final lastTimestamp = lastLog['createdAt'] as Timestamp?;

      if (lastTimestamp != null) {
        final lastTime = lastTimestamp.toDate();
        final now = DateTime.now();

        final difference = now.difference(lastTime);

        if (difference.inMinutes < 10) {
          print("⏳ Emergency cooldown active. No SMS sent.");

          // Still log event
          await saveEmergencyLog(
            userId: userId,
            triggerType: triggerType,
            detectedText: message,
            keywordsFound: keywordsFound,
            contactsNotified: 0,
          );

          return;
        }
      }
    }

    // 2️⃣ Fetch emergency contacts
    final snapshot = await _firestore
        .collection('emergency_contacts')
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      print("No emergency contacts found.");
      return;
    }

    // 3️⃣ Send SMS to each contact
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final phone = data['phone'];

      final formattedPhone = _formatPhoneNumber(phone);

      await _sendEmergencySMS(
        phone: formattedPhone,
        userMessage: message,
      );

      notifiedCount++;
    }

    // 4️⃣ Save emergency log
    await saveEmergencyLog(
      userId: userId,
      triggerType: triggerType,
      detectedText: message,
      keywordsFound: keywordsFound,
      contactsNotified: notifiedCount,
    );

    print("🚨 Emergency flow completed.");
  }


  Future<void> _sendEmergencySMS({
    required String phone,
    required String userMessage,
  }) async {
    try {
      final callable =
      FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendEmergencySMS');

      await callable.call({
        "phone": phone,
        "message":
        "🚨 Emergency Alert: User may be in crisis.\nMessage: $userMessage",
      });

      print("✅ SMS sent via Firebase Function");
    } catch (e) {
      print("❌ SMS error: $e");
    }
  }
  String _formatPhoneNumber(String phone) {
    phone = phone.trim();

    if (phone.startsWith('+')) return phone;

    if (phone.startsWith('0')) {
      return '+91${phone.substring(1)}';
    }

    if (phone.length == 10) {
      return '+91$phone';
    }

    return phone;
  }

}
