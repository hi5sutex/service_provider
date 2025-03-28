import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_message.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_service.dart';
import 'package:service_provider/theme.dart';
import 'package:service_provider/CustomSnackBar.dart'; // Ensure this path is correct

class ProviderChatScreen extends StatefulWidget {
  final String providerId;
  final String userId;
  final String providerEmail;
  final String userEmail;
  final String userName;
  final String providerName;

  const ProviderChatScreen({
    Key? key,
    required this.providerId,
    required this.userId,
    required this.providerEmail,
    required this.userEmail,
    required this.userName,
    required this.providerName,
  }) : super(key: key);

  @override
  _ProviderChatScreenState createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isFirstLoad = true;

  final List<String> _quickChats = [
    'When are you available?',
    'Can you share more details?',
    'I’ll get back to you soon.',
    'What’s your budget?',
    'Thanks for reaching out!',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _markMessagesAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLoad) {
        _scrollToBottom();
        _isFirstLoad = false;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  void _markMessagesAsRead() async {
    // final chatRoomId = _chatService.getChatRoomId(widget.providerId, widget.userId);
    // await _chatService.markMessagesAsRead(chatRoomId, widget.providerId, widget.userEmail);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendQuickChat(String message) async {
    try {
      await _chatService.sendMessage(
        senderId: widget.providerId,
        receiverId: widget.userId,
        senderEmail: widget.providerEmail,
        receiverEmail: widget.userEmail,
        message: message,
      );
      _scrollToBottom();
      _focusNode.requestFocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showUserDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProviderTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = userData['name'] ?? 'Unknown User';
          final email = userData['email'] ?? 'No email';
          final phone = userData['phone'] ?? 'No phone';
          final bio = userData['bio'] ?? 'No bio';
          final profileImage = userData['profileImage'] ?? 'https://avatar.iran.liara.run/public';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: CachedNetworkImageProvider(profileImage),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Name: $name', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Email: $email', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Phone: $phone', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Bio: $bio', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Inside _ProviderChatScreenState class

  void _showPhoneSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const CustomSnackBar(
          message: 'Call Facility coming soon',
          type: 'success', // Keeping success for green styling
          icon: FontAwesomeIcons.clock, // Custom icon for "coming soon"
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showVideoSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const CustomSnackBar(
          message: 'Video call Facility coming soon',
          type: 'success', // Keeping success for green styling
          icon: FontAwesomeIcons.clock, // Custom icon for "coming soon"
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, left: 8, right: 16, bottom: 8),
            decoration: BoxDecoration(
              gradient: ProviderTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: ProviderTheme.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    color: ProviderTheme.onPrimaryTextColor,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(0),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showUserDetails(context),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                    builder: (context, snapshot) {
                      String profileImage = 'https://avatar.iran.liara.run/public';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        profileImage = userData['profileImage'] ?? profileImage;
                      }
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(profileImage),
                            backgroundColor: ProviderTheme.primaryColor.withOpacity(0.1),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: ProviderTheme.onPrimaryTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Online',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ProviderTheme.successColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.phone,
                    color: ProviderTheme.onPrimaryTextColor,
                    size: 18,
                  ),
                  onPressed: _showPhoneSnackBar,
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.video,
                    color: ProviderTheme.onPrimaryTextColor,
                    size: 18,
                  ),
                  onPressed: _showVideoSnackBar,
                ),
              ],
            ),
          ),
          Expanded(
            child: ChatMessageList(
              userId: widget.providerId,
              receiverId: widget.userId,
              senderEmail: widget.providerEmail,
              onNewMessage: _scrollToBottom,
            ),
          ),
          MessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            quickChats: _quickChats,
            onSend: (message) async {
              try {
                await _chatService.sendMessage(
                  senderId: widget.providerId,
                  receiverId: widget.userId,
                  senderEmail: widget.providerEmail,
                  receiverEmail: widget.userEmail,
                  message: message,
                );
                _scrollToBottom();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send message: $e')),
                );
              }
            },
            onQuickChat: _sendQuickChat,
          ),
        ],
      ),
    );
  }
}

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> quickChats;
  final Future<void> Function(String) onSend;
  final void Function(String) onQuickChat;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.quickChats,
    required this.onSend,
    required this.onQuickChat,
  }) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: ProviderTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.controller.text.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.quickChats.map((chat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => widget.onQuickChat(chat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: ProviderTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: ProviderTheme.dividerColor),
                        ),
                        child: Text(
                          chat,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ProviderTheme.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (widget.controller.text.isEmpty) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.paperclip,
                  color: ProviderTheme.secondaryTextColor,
                  size: 22,
                ),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: ProviderTheme.primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: ProviderTheme.disabledTextColor),
                    filled: true,
                    fillColor: ProviderTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ProviderTheme.primaryGradient,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: ProviderTheme.onPrimaryTextColor,
                    size: 22,
                  ),
                  onPressed: () async {
                    if (widget.controller.text.trim().isNotEmpty) {
                      String messageText = widget.controller.text.trim();
                      widget.controller.clear();
                      widget.focusNode.requestFocus();
                      await widget.onSend(messageText);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessageList extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String senderEmail;
  final VoidCallback onNewMessage;

  const ChatMessageList({
    Key? key,
    required this.userId,
    required this.receiverId,
    required this.senderEmail,
    required this.onNewMessage,
  }) : super(key: key);

  @override
  _ChatMessageListState createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService().getMessages(widget.userId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Start chatting!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        } else {
          final messages = snapshot.data!;
          if (messages.length > _previousMessageCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
              widget.onNewMessage();
            });
            _previousMessageCount = messages.length;
          }
          return ListView.builder(
            key: const ValueKey('chat_message_list'),
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isSender = message.senderEmail == widget.senderEmail;
              return buildChatBubble(
                isSender: isSender,
                text: message.message,
                time: message.timestamp.toDate().toString().substring(11, 16),
              );
            },
          );
        }
      },
    );
  }

  Widget buildChatBubble({required bool isSender, required String text, required String time}) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSender
              ? ProviderTheme.primaryGradient
              : const LinearGradient(
            colors: [
              Color(0xFFE8ECEF),
              Color(0xFFDDE3E9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSender ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isSender ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: isSender
                      ? ProviderTheme.onPrimaryTextColor
                      : ProviderTheme.primaryTextColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 10,
                color: isSender
                    ? ProviderTheme.onPrimaryTextColor.withOpacity(0.7)
                    : ProviderTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}