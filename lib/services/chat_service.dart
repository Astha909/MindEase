import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    required String sender,
    required String text,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await messageRef.add({
      'sender': sender, // user | ai
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),

    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Listen to messages
  Stream<QuerySnapshot> listenToMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
