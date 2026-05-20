import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../controllers/chat_controller.dart';

import '../widgets/chat_bubble.dart';
import '../widgets/ai_typing_loader.dart';
import '../widgets/chat_error_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ChatController chatController;
  final String userId;
  final String mood;
  final Color moodColor;

  const ChatScreen({
    super.key,
    required this.chatController,
    required this.userId,
    required this.mood,
    required this.moodColor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _bgController;

  String? _chatId;
  bool _pressed = false;
  bool _hideControllerError = false;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _initChat();
  }

  Future<void> _initChat() async {
    final id = await widget.chatController.getOrCreateChat(widget.userId);

    if (!mounted) return;

    setState(() {
      _chatId = id;
    });
  }

  List<Color> getMoodGradient() {
    switch (widget.mood.toLowerCase()) {
      case "happy":
        return [
          const Color(0xFFFFD89B),
          const Color(0xFFFFB6B9),
          const Color(0xFFFFECD2),
        ];

      case "sad":
        return [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
        ];

      case "angry":
        return [
          const Color(0xFF870000),
          const Color(0xFF190A05),
          const Color(0xFFFF512F),
        ];

      case "fearful":
        return [
          const Color(0xFF232526),
          const Color(0xFF414345),
          const Color(0xFF000000),
        ];

      case "disgusted":
        return [
          const Color(0xFF654EA3),
          const Color(0xFFEAafc8),
          const Color(0xFF5B247A),
        ];

      case "surprised":
        return [
          const Color(0xFFF7971E),
          const Color(0xFFFFD200),
          const Color(0xFFFFF6B7),
        ];

      default:
        return [
          const Color(0xFFB0BEC5),
          const Color(0xFFECEFF1),
          const Color(0xFFCFD8DC),
        ];
    }
  }

  Future<void> _sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty || _chatId == null || widget.chatController.isLoading) {
      return;
    }

    _messageController.clear();

    setState(() {
      _hideControllerError = false;
    });

    await widget.chatController.handleMessage(
      chatId: _chatId!,
      userId: widget.userId,
      message: message,
    );

    _scrollToBottom();
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> message) {
    if (_chatId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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

  void _showEditDialog(Map<String, dynamic> message) {
    if (_chatId == null) return;

    final controller = TextEditingController(
      text: message['text'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text("Edit Message"),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
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
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.moodColor.withOpacity(0.25),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chhotu 🤖",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${widget.mood} mode ✨",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -1 + (_bgController.value * 2),
                  -1,
                ),
                end: Alignment(
                  1,
                  1 - (_bgController.value * 2),
                ),
                colors: getMoodGradient(),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.moodColor.withOpacity(0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.moodColor.withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: widget.chatController,
                          builder: (context, _) {
                            final isTyping = widget.chatController.isLoading;

                            final hasError =
                                widget.chatController.errorMessage != null &&
                                    !_hideControllerError;

                            return StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _chatId == null
                                  ? Stream.value([])
                                  : widget.chatController.listenToMessages(
                                      _chatId!,
                                    ),
                              builder: (context, snapshot) {
                                final docs = snapshot.data ?? [];

                                if (docs.length != _lastMessageCount) {
                                  _lastMessageCount = docs.length;

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToBottom();
                                  });
                                }

                                if (docs.isEmpty && !isTyping && !hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(
                                                0.16,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.22,
                                                ),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome_rounded,
                                              color: Colors.white,
                                              size: 34,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            "Start sharing what’s on your mind ✨",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.88,
                                              ),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Chhotu is here to listen and support you.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.68,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: docs.length +
                                      (isTyping ? 1 : 0) +
                                      (hasError ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (isTyping && index == 0) {
                                      return const Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: AITypingLoader(),
                                      );
                                    }

                                    if (hasError &&
                                        index == (isTyping ? 1 : 0)) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: ChatErrorBubble(
                                          onRetry: () {
                                            setState(() {
                                              _hideControllerError = true;
                                            });
                                          },
                                        ),
                                      );
                                    }

                                    int adjustedIndex = index;

                                    if (isTyping) {
                                      adjustedIndex--;
                                    }

                                    if (hasError) {
                                      adjustedIndex--;
                                    }

                                    if (adjustedIndex < 0 ||
                                        adjustedIndex >= docs.length) {
                                      return const SizedBox.shrink();
                                    }

                                    final data =
                                        docs[docs.length - 1 - adjustedIndex];

                                    final isUser = data['sender'] == "user";

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: ChatBubble(
                                        isUser: isUser,
                                        text: data['text'] ?? '',
                                        onLongPress: isUser
                                            ? () => _showMessageOptions(data)
                                            : null,
                                      )
                                          .animate()
                                          .fade(
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
                                          )
                                          .slideY(
                                            begin: 0.25,
                                            end: 0,
                                            curve: Curves.easeOut,
                                            duration: const Duration(
                                              milliseconds: 350,
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
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.moodColor.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) {
                                  _sendMessage(
                                    _messageController.text,
                                  );
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      "Tell Chhotu what's on your mind...",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _messageController,
                              builder: (context, value, _) {
                                final canSend = value.text.trim().isNotEmpty &&
                                    !widget.chatController.isLoading &&
                                    _chatId != null;

                                return GestureDetector(
                                  onTapDown: canSend
                                      ? (_) {
                                          setState(() {
                                            _pressed = true;
                                          });
                                        }
                                      : null,
                                  onTapUp: canSend
                                      ? (_) {
                                          setState(() {
                                            _pressed = false;
                                          });
                                        }
                                      : null,
                                  onTapCancel: canSend
                                      ? () {
                                          setState(() {
                                            _pressed = false;
                                          });
                                        }
                                      : null,
                                  onTap: canSend
                                      ? () {
                                          _sendMessage(
                                            _messageController.text,
                                          );
                                        }
                                      : null,
                                  child: AnimatedOpacity(
                                    opacity: canSend ? 1 : 0.45,
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    child: AnimatedScale(
                                      scale: _pressed ? 0.88 : 1,
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.moodColor,
                                              widget.moodColor.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.moodColor
                                                  .withOpacity(0.35),
                                              blurRadius: 18,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
