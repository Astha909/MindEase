import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  final ChatController chatController;
  final String userId;

  const ChatScreen({
    super.key,
    required this.chatController,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  String? _chatId;
  bool _loadingChat = true;

  bool _showTyping = false;
  bool _showError = false;

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _typingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
    _initChat();
  }

  /// ✅ UPDATED FUNCTION (Safe + mounted check)
  Future<void> _initChat() async {
    final id =
    await widget.chatController.getOrCreateChat(widget.userId);

    if (!mounted) return;

    if (id.isEmpty) return;

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
    _typingController.dispose();
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

  /// ✅ UPDATED FUNCTION (Safe mounted checks)
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_chatId == null) return;

    if (!mounted) return;
    setState(() {
      _sending = true;
      _showTyping = true;
      _showError = false;
    });

    try {
      await widget.chatController.handleMessage(
        chatId: _chatId!,
        userId: widget.userId,
        message: text,
      );

      _messageController.clear();
      await Future.delayed(const Duration(seconds: 1));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showError = true;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _showTyping = false;
      });
    }

    _scrollToBottom();
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingChat || _chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chat with AI")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                /// ✅ Removed null assertion (!)
                stream: widget.chatController
                    .listenToMessages(_chatId ?? ""),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("Failed to load messages"));
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data.docs;

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length +
                        (_showTyping ? 1 : 0) +
                        (_showError ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_showTyping &&
                          index == docs.length) {
                        return _buildTypingBubble();
                      }

                      if (_showError &&
                          index ==
                              docs.length +
                                  (_showTyping ? 1 : 0)) {
                        return _buildErrorBubble();
                      }

                      final data =
                      docs[index].data() as Map<String, dynamic>;

                      final isUser =
                          data['sender'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6),
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10),
                          constraints:
                          const BoxConstraints(
                              maxWidth: 250),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(
                                colors: [
                                  Color(0xff4facfe),
                                  Color(0xff00f2fe)
                                ])
                                : const LinearGradient(
                                colors: [
                                  Color(0xffe0e0e0),
                                  Color(0xffcfcfcf)
                                ]),
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                data['text'] ?? '',
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              if (data['timestamp'] != null)
                                Text(
                                  _formatTime(
                                      data['timestamp']),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isUser
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              color:
              const Color.fromARGB(255, 234, 237, 238),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:
                      const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(
                              Radius.circular(30)),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(
                            horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:
                    Colors.blueAccent,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
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

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: _typingController,
        child: Container(
          margin:
          const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius:
            BorderRadius.circular(16),
          ),
          child: const Text(
            "AI is typing...",
            style:
            TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin:
        const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: const Text(
          "Something went wrong 😔",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}