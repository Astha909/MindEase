import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../controllers/emergency_controller.dart';

import '../widgets/chat_bubble.dart';
import '../widgets/ai_typing_loader.dart';
import '../widgets/chat_error_bubble.dart';

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

  Map<String, dynamic>? _lastDocument;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _initChat();

    _scrollController.addListener(_handleScroll);
  }

  Future<void> _initChat() async {
    final id = await widget.chatController.getOrCreateChat(widget.userId);

    if (!mounted) return;

    setState(() {
      _chatId = id;
      _loadingChat = false;
    });
  }

  void _handleScroll() async {
    if (!_scrollController.hasClients || _chatId == null) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        _lastDocument != null) {
      setState(() => _isLoadingMore = true);

      try {
        final messages = await widget.chatController.fetchMessages(
          chatId: _chatId!,
          lastMessage: _lastDocument!,
          limit: 20,
        );

        if (messages.isNotEmpty) {
          _lastDocument = messages.last;
        } else {
          _hasMoreMessages = false;
        }
      } catch (e) {
        debugPrint("Pagination error: $e");
      }

      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _chatId == null) {
      return;
    }

    final message = text.trim();

    _messageController.clear();

    setState(() => _showError = false);

    try {
      final keywords = _emergencyController.checkEmergencyKeywords(message);

      if (keywords.isNotEmpty) {
        final confirm = await _showEmergencyConfirmation();

        if (confirm == true) {
          await _emergencyController.triggerEmergency(
            userId: widget.userId,
            message: message,
            keywordsFound: keywords,
            isConfirmed: true,
          );
        }
      }

      await widget.chatController.handleMessage(
        chatId: _chatId!,
        userId: widget.userId,
        message: message,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _showError = true);
      }
    }

    _scrollToBottom();
  }

  Future<bool?> _showEmergencyConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Alert 🚨"),
        content: const Text(
          "We detected something serious.\nDo you want to alert your emergency contacts?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(
    Map<String, dynamic> message,
  ) {
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

  void _showDeleteConfirmation(
    Map<String, dynamic> message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text(
          "Are you sure you want to delete this message?",
        ),
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

  void _showEditDialog(
    Map<String, dynamic> message,
  ) {
    final controller = TextEditingController(
      text: message['text'],
    );

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

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingChat) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Chhotu 🤖"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: widget.chatController,
                builder: (context, _) {
                  final isTyping = widget.chatController.isLoading;

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.chatController.listenToMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!;

                      if (_lastDocument == null && docs.isNotEmpty) {
                        _lastDocument = docs.last;
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length +
                            (isTyping ? 1 : 0) +
                            (_showError ? 1 : 0) +
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          /// PAGINATION LOADER
                          if (_isLoadingMore && index == docs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          /// AI TYPING
                          if (isTyping && index == 0) {
                            return const AITypingLoader();
                          }

                          /// ERROR BUBBLE
                          if (_showError && index == (isTyping ? 1 : 0)) {
                            return ChatErrorBubble(
                              onRetry: () {
                                setState(() {
                                  _showError = false;
                                });
                              },
                            );
                          }

                          /// FIXED INDEX
                          int adjustedIndex = index;

                          if (isTyping) {
                            adjustedIndex--;
                          }

                          if (_showError) {
                            adjustedIndex--;
                          }

                          if (_isLoadingMore) {
                            adjustedIndex--;
                          }

                          if (adjustedIndex < 0 ||
                              adjustedIndex >= docs.length) {
                            return const SizedBox.shrink();
                          }

                          final data = docs[docs.length - 1 - adjustedIndex];

                          final isUser = data['sender'] == "user";

                          return ChatBubble(
                            isUser: isUser,
                            text: data['text'] ?? '',
                            onLongPress:
                                isUser ? () => _showMessageOptions(data) : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color: const Color.fromARGB(255, 234, 237, 238),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(30),
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _pressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _pressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _pressed = false;
                      });
                    },
                    onTap: () {
                      _sendMessage(
                        _messageController.text.trim(),
                      );
                    },
                    child: AnimatedScale(
                      scale: _pressed ? 0.9 : 1,
                      duration: const Duration(
                        milliseconds: 100,
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
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
}
