// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


// 🔐 TEMP: Enable real SMS only on your device
const bool useRealSMS = false;

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
    final found = <String>[];

    for (final word in keywords) {
      if (lowerMessage.contains(word)) {
        found.add(word);
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

      await _sendMockSMS(
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


  // 📩 MOCK SMS FUNCTION (Twilio will replace this later)
  Future<void> _sendMockSMS({
    required String phone,
    required String userMessage,
  }) async {
    if (!useRealSMS) {
      print("🔹 MOCK SMS to $phone");
      print("Message: $userMessage");
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    try {
      // ⚠️ DEV ONLY: Add your Twilio credentials locally
      const String accountSid = " ";
      const String authToken = " ";
      const String twilioPhone = " ";

      final url = Uri.parse(
          "https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json");

      final response = await http.post(
        url,
        headers: {
          "Authorization":
          "Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}",
        },
        body: {
          "From": twilioPhone,
          "To": phone,
          "Body":
          "🚨 Emergency Alert: User may be in crisis.\nMessage: $userMessage",
        },
      );

      print("Twilio response: ${response.statusCode}");
    } catch (e) {
      print("SMS error: $e");
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
