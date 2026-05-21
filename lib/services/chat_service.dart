// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AES encryption setup
  final _key = encrypt.Key.fromUtf8(
    '12345678901234567890123456789012',
  );

  final _iv = encrypt.IV.fromLength(16);

  late final encrypt.Encrypter _aes = encrypt.Encrypter(
    encrypt.AES(_key),
  );

  // Encrypt before Firestore storage
  String _encrypt(String text) {
    return _aes
        .encrypt(
          text,
          iv: _iv,
        )
        .base64;
  }

  // Decrypt before UI usage
  String _decrypt(String encryptedText) {
    try {
      // Skip normal text
      if (!encryptedText.contains('=') && encryptedText.length < 16) {
        return encryptedText;
      }

      return _aes.decrypt64(
        encryptedText,
        iv: _iv,
      );
    } catch (e) {
      return encryptedText;
    }
  }

  // Create or get chat
  Future<String> getOrCreateChat(
    String userId,
  ) async {
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

    final doc = await _firestore
        .collection('chats')
        .add({
      'userId': userId,
      'lastMessage': '',
      'timestamp':
      FieldValue.serverTimestamp(),
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

    await messageRef.add({
      'sender': sender,
      'userId': userId,
      'text': _encrypt(text),
      'encrypted': true,
      'timestamp': FieldValue.serverTimestamp(),
      'sentiment': sentiment,
      'isCrisis': isCrisis,
      'crisisLevel': crisisLevel,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': _encrypt(text),
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

    await messageRef.update({
      'text': _encrypt(newText),
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
  Stream<List<Map<String, dynamic>>> listenToMessages(String chatId) {
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

            if (data['encrypted'] == true && data['text'] != null) {
              data['text'] = _decrypt(
                data['text'],
              );
            }
            if (data['encrypted'] == true && data['text'] != null) {
              data['text'] = _decrypt(data['text']);
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
    Map<String, dynamic>? lastMessage,
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

    if (lastMessage != null && lastMessage['timestamp'] != null) {
      query = query.startAfter([
        lastMessage['timestamp'],
      ]);
    }

    final snapshot = await query.get().timeout(
          const Duration(seconds: 10),
        );

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['encrypted'] == true && data['text'] != null) {
        data['text'] = _decrypt(data['text']);
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

      if (data['encrypted'] == true) {
        text = _decrypt(text);
      }

      final sender = data['sender'] ?? 'user';

      return "$sender: $text";
    }).toList();

    return messages;
  }
}
