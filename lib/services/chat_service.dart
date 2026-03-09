// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Simple encryption helpers
  String _encrypt(String text) {
    return text.split('').reversed.join();
  }

  String _decrypt(String text) {
    return text.split('').reversed.join();
  }
  // 1. Create or get chat
  Future<String> getOrCreateChat(String userId) async {
    print("🔎 getOrCreateChat started for user: $userId");

    final query = await _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    print("📦 Query completed. Docs: ${query.docs.length}");

    if (query.docs.isNotEmpty) {
      print("✅ Existing chat found");
      return query.docs.first.id;
    }

    print("🆕 Creating new chat");

    final doc = await _firestore.collection('chats').add({
      'userId': userId,
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("🎉 Chat created: ${doc.id}");

    return doc.id;
  }

  // 2. Send message
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String sender,
    required String text,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await messageRef.add({
      'sender': sender, // user | ai
      'userId': userId,
      'text': _encrypt(text),
      'timestamp': FieldValue.serverTimestamp(),

    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': _encrypt(text),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String userId,
    required String newText,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await messageRef.get();

    if (!snapshot.exists) {
      throw Exception("Message not found");
    }

    final data = snapshot.data();

    if (data?['userId'] != userId) {
      throw Exception("You can only edit your own message");
    }

    await messageRef.update({
      'text': _encrypt(newText),
      'edited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await messageRef.get();

    if (!snapshot.exists) {
      throw Exception("Message not found");
    }

    final data = snapshot.data();

    if (data?['userId'] != userId) {
      throw Exception("You can only delete your own message");
    }

    await messageRef.delete();
  }

  // 3. Listen to messages
  Stream<List<Map<String, dynamic>>> listenToMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        if (data['text'] != null) {
          data['text'] = _decrypt(data['text']);
        }

        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // 4. Fetch messages with pagination
  Future<QuerySnapshot> fetchMessages({
    required String chatId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }
}
