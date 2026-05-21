// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AES encryption setup
  final _key = encrypt.Key.fromUtf8(
    '12345678901234567890123456789012',
  );

  late final encrypt.Encrypter _aes = encrypt.Encrypter(
    encrypt.AES(_key),
  );

  // Decrypt before UI usage
  String _decrypt(
    String encryptedText,
    String? ivText,
  ) {
    try {
      // Old/plain messages fallback
      if (ivText == null || ivText.isEmpty) {
        return encryptedText;
      }

      final iv = encrypt.IV.fromBase64(ivText);

      return _aes.decrypt64(
        encryptedText,
        iv: iv,
      );
    } catch (e) {
      return encryptedText;
    }
  }

  // Create or get chat
  Future<String> getOrCreateChat(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
      throw Exception("Invalid userId");
    }

    final query = await _firestore
        .collection('chats')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .limit(1)
        .get()
        .timeout(
          const Duration(seconds: 10),
        );

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final doc = await _firestore.collection('chats').add({
      'userId': userId,
      'lastMessage': '',
      'lastMessageIv': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String sender,
    required String text,
    String? sentiment,
    bool isCrisis = false,
    String crisisLevel = "none",
  }) async {
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages');

    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted = _aes.encrypt(
      text,
      iv: iv,
    );

    await messageRef.add({
      'sender': sender,
      'userId': userId,
      'text': encrypted.base64,
      'iv': iv.base64,
      'encrypted': true,
      'timestamp': FieldValue.serverTimestamp(),
      'sentiment': sentiment,
      'isCrisis': isCrisis,
      'crisisLevel': crisisLevel,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': encrypted.base64,
      'lastMessageIv': iv.base64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Edit message
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
      throw Exception(
        "Message not found",
      );
    }

    final data = snapshot.data();

    if (data?['userId'] != userId) {
      throw Exception(
        "You can only edit your own message",
      );
    }

    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted = _aes.encrypt(
      newText,
      iv: iv,
    );

    await messageRef.update({
      'text': encrypted.base64,
      'iv': iv.base64,
      'edited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete message
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
      throw Exception(
        "Message not found",
      );
    }

    final data = snapshot.data();

    if (data?['userId'] != userId) {
      throw Exception(
        "You can only delete your own message",
      );
    }

    await messageRef.delete();
  }

  // Listen to realtime messages
  Stream<List<Map<String, dynamic>>> listenToMessages(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .limit(50)
        .snapshots()
        .handleError((e) {
      print(
        "Firestore stream error: $e",
      );
    }).map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(
              doc.data(),
            );

            if (data['timestamp'] == null) {
              return null;
            }

            if (data['encrypted'] == true &&
                data['text'] != null &&
                data['iv'] != null) {
              data['text'] = _decrypt(
                data['text'] ?? '',
                data['iv'],
              );
            }

            data['id'] = doc.id;

            return data;
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }

  // Fetch paginated messages
  Future<QuerySnapshot> fetchMessages({
    required String chatId,
    dynamic lastDocument,
    int limit = 15,
  }) async {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: false,
        )
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get().timeout(
          const Duration(seconds: 10),
        );

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['encrypted'] == true &&
          data['text'] != null &&
          data['iv'] != null) {
        data['text'] = _decrypt(
          data['text'] ?? '',
          data['iv'],
        );
      }
    }

    return snapshot;
  }

  // Recent conversation memory
  Future<List<String>> getRecentConversation(
    String chatId, {
    int limit = 3,
  }) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .limit(limit)
        .get()
        .timeout(
          const Duration(seconds: 10),
        );

    final messages = snapshot.docs.reversed.map((doc) {
      final data = doc.data();

      String text = data['text'] ?? '';

      if (data['encrypted'] == true && data['iv'] != null) {
        text = _decrypt(
          text,
          data['iv'],
        );
      }

      final sender = data['sender'] ?? 'user';

      return "$sender: $text";
    }).toList();

    return messages;
  }
}
