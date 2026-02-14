import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/chat_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final ChatController chatController;

  const ChatScreen({super.key, required this.chatController});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  String? _chatId;
  bool _loadingChat = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  Future<void> _initChat() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final id =
    await widget.chatController.getOrCreateChat(userId);


    setState(() {
      _chatId = id;
      _loadingChat = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    super.didChangeMetrics();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _sending = true;
    });

    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await widget.chatController
          .handleMessage(userId: userId, message: text);
      _messageController.clear();
    } catch (_) {
      // optional error handling
    } finally {
      setState(() {
        _sending = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingChat) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chat with AI")),
      body: SafeArea(
        child: Column(
          children: [
            /// MESSAGE LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                widget.chatController.listenToMessages(_chatId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                      docs[index].data() as Map<String, dynamic>;

                      final isUser = data['sender'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          constraints:
                          const BoxConstraints(maxWidth: 250),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(colors: [
                              Color(0xff4facfe),
                              Color(0xff00f2fe)
                            ])
                                : const LinearGradient(colors: [
                              Color(0xffe0e0e0),
                              Color(0xffcfcfcf)
                            ]),
                            borderRadius: BorderRadius.only(
                              topLeft:
                              const Radius.circular(16),
                              topRight:
                              const Radius.circular(16),
                              bottomLeft:
                              Radius.circular(isUser ? 16 : 0),
                              bottomRight:
                              Radius.circular(isUser ? 0 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.1),
                                blurRadius: 4,
                                offset:
                                const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            data['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// INPUT FIELD
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              color: const Color.fromARGB(255, 234, 237, 238),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(30)),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: _sending
                          ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2)
                          : const Icon(Icons.send,
                          color: Colors.white),
                      onPressed: _sending
                          ? null
                          : () => _sendMessage(
                          _messageController.text
                              .trim()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
