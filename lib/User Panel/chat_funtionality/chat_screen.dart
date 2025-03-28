import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_service.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_message.dart';
import 'package:service_provider/theme.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String senderEmail;
  final String receiverEmail;
  final String providerName;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.receiverId,
    required this.senderEmail,
    required this.receiverEmail,
    required this.providerName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // Changed to scroll to bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF060644), // Matches #060644 (Primary)
                Color(0xFF1A237E), // Matches #1A237E (Gradient end)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            size: screenWidth * 0.06,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: screenWidth * 0.05,
              backgroundImage:
              const NetworkImage('https://avatar.iran.liara.run/public'),
            ),
            SizedBox(width: screenWidth * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName,
                  style: TextStyle(
                    color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: ProviderTheme.successColor, // Matches #388E3C (Success Text)
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.call,
              color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
              size: screenWidth * 0.06,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
              size: screenWidth * 0.06,
            ),
            onPressed: () {},
          ),
        ],
        centerTitle: false,
        elevation: 4,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4), // Matches #000000 with opacity
        iconTheme: IconThemeData(
          color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
        ),
      ),
      backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.userId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: ProviderTheme.errorTextColor, // Matches #D32F2F (Error Text)
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start chatting!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                      ),
                    ),
                  );
                } else {
                  final messages = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    reverse: false, // Changed to false to match screenshot (newest messages at bottom)
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message.senderEmail == widget.senderEmail;
                      return buildChatBubble(
                        isSender: isSender,
                        text: message.message,
                        time: message.timestamp.toDate().toString().substring(11, 16),
                        screenWidth: screenWidth,
                      );
                    },
                  );
                }
              },
            ),
          ),
          buildMessageInput(screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget buildChatBubble({
    required bool isSender,
    required String text,
    required String time,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.025,
              ),
              decoration: BoxDecoration(
                color: isSender
                    ? ProviderTheme.primaryColor // Matches #060644 (Primary)
                    : ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isSender
                          ? ProviderTheme.onPrimaryTextColor // Matches #FFFFFF (On Primary Text)
                          : ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: isSender
                          ? ProviderTheme.onPrimaryTextColor.withOpacity(0.7) // Matches #FFFFFF with opacity
                          : ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageInput(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
        boxShadow: [
          BoxShadow(
            color: ProviderTheme.shadowColor.withOpacity(0.2), // Matches #000000 with opacity
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attachment,
              color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
              size: screenWidth * 0.06,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.02,
                ),
              ),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                size: screenWidth * 0.06,
              ),
              onPressed: () async {
                if (_messageController.text.trim().isNotEmpty) {
                  try {
                    await _chatService.sendMessage(
                      senderId: widget.userId,
                      receiverId: widget.receiverId,
                      senderEmail: widget.senderEmail,
                      receiverEmail: widget.receiverEmail,
                      message: _messageController.text.trim(),
                    );
                    _messageController.clear();
                    _scrollToBottom();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send message: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}