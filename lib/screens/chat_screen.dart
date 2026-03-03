import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  bool _loadingChat = true;
  bool _showError = false;

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initChat();
  }

  Future<void> _initChat() async {
    final id = await widget.chatController.getOrCreateChat(widget.userId);

    setState(() {
      _chatId = id;
      _loadingChat = false;
    });
  }

  @override
  void dispose() {
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _chatId == null) return;

    setState(() {
      _showError = false;
    });

    try {
      await widget.chatController.handleMessage(
        chatId: _chatId!,
        userId: widget.userId,
        message: text,
      );

      _messageController.clear();
    } catch (_) {
      setState(() {
        _showError = true;
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
              child: AnimatedBuilder(
                animation: widget.chatController,
                builder: (context, _) {
                  final isTyping = widget.chatController.isLoading;

                  return StreamBuilder(
                    stream: widget.chatController.listenToMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length +
                            (isTyping ? 1 : 0) +
                            (_showError ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (isTyping && index == docs.length) {
                            return _buildTypingBubble();
                          }

                          if (_showError &&
                              index == docs.length + (isTyping ? 1 : 0)) {
                            return _buildErrorBubble();
                          }

                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          final isUser = data['sender'] == "user";

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 250),
                              decoration: BoxDecoration(
                                gradient: isUser
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xff4facfe),
                                          Color(0xff00f2fe)
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xffe0e0e0),
                                          Color(0xffcfcfcf)
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            /// INPUT AREA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color.fromARGB(255, 234, 237, 238),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),

                      onPressed: () => _sendMessage(
                        _messageController.text.trim(),
                      ),
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
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "AI is typing...",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Something went wrong 😔",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
