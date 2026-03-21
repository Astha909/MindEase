import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../controllers/emergency_controller.dart';

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
  final EmergencyController _emergencyController = EmergencyController();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  bool _loadingChat = true;
  bool _showError = false;

  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  dynamic _lastDocument;

  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initChat();
    _scrollController.addListener(_handleScroll);
  }

  Future<void> _initChat() async {
    final id = await widget.chatController.getOrCreateChat(widget.userId);

    setState(() {
      _chatId = id;
      _loadingChat = false;
    });
  }

  void _handleScroll() async {
    if (_scrollController.position.pixels <= 50 &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        _chatId != null) {
      _isLoadingMore = true;

      await widget.chatController.fetchMessages(
        chatId: _chatId!,
        lastDocument: _lastDocument,
        limit: 20,
      );

      _isLoadingMore = false;
    }
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
      final keywords = _emergencyController.checkEmergencyKeywords(text);

      if (keywords.isNotEmpty) {
        await _emergencyController.triggerEmergency(
          userId: widget.userId,
          message: text,
          keywordsFound: keywords,
          isConfirmed: true,
        );
      }

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

  /// MESSAGE OPTIONS
  void _showMessageOptions(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Message Options"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(message);
            },
            child: const Text("Edit"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(message);
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  /// DELETE CONFIRMATION DIALOG
  void _showDeleteConfirmation(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await widget.chatController.deleteMessage(
                chatId: _chatId!,
                messageId: message['id'],
                userId: widget.userId,
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// EDIT MESSAGE DIALOG
  void _showEditDialog(Map<String, dynamic> message) {
    final controller = TextEditingController(text: message['text']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Message"),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();

              if (newText.isNotEmpty) {
                await widget.chatController.editMessage(
                  chatId: _chatId!,
                  messageId: message['id'],
                  userId: widget.userId,
                  newText: newText,
                );
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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

                      final docs = snapshot.data!;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length +
                            (isTyping ? 1 : 0) +
                            (_showError ? 1 : 0) +
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingMore && index == 0) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (isTyping && index == docs.length) {
                            return _buildTypingBubble();
                          }

                          if (_showError &&
                              index == docs.length + (isTyping ? 1 : 0)) {
                            return _buildErrorBubble();
                          }

                          final data = docs[index];
                          final isUser = data['sender'] == "user";

                          Widget bubble = Align(
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

                          if (isUser) {
                            bubble = GestureDetector(
                              onLongPress: () => _showMessageOptions(data),
                              child: bubble,
                            );
                          }

                          return bubble;
                        },
                      );
                    },
                  );
                },
              ),
            ),
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
