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
        0.0,
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.primaryColorCustom, size: screenWidth * 0.06),
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
                      color: AppTheme.primaryColorCustom,
                      fontSize: screenWidth * 0.045),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                      color: AppTheme.providerGreen,
                      fontSize: screenWidth * 0.03),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.secondaryColorCustom,
        elevation: 1,
        iconTheme: IconThemeData(color: AppTheme.primaryColorCustom),
      ),
      backgroundColor: AppTheme.secondaryColorCustom, // Changed to white
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.userId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColorCustom));
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: screenWidth * 0.04)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No messages yet. Start chatting!',
                          style: TextStyle(fontSize: screenWidth * 0.04)));
                } else {
                  final messages = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message.senderEmail == widget.senderEmail;
                      return buildChatBubble(
                        isSender: isSender,
                        text: message.message,
                        time:
                        message.timestamp.toDate().toString().substring(11, 16),
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
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: isSender ? Colors.blue : AppTheme.secondaryColorCustom,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: isSender ? AppTheme.secondaryColorCustom : Colors.black,
                  fontSize: screenWidth * 0.035),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              time,
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                color: isSender
                    ? AppTheme.secondaryColorCustom.withOpacity(0.7)
                    : AppTheme.greyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageInput(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      color: AppTheme.secondaryColorCustom,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attachment,
                color: AppTheme.greyLight, size: screenWidth * 0.06),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, vertical: 0),
              ),
              style: TextStyle(fontSize: screenWidth * 0.035),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue, size: screenWidth * 0.06),
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
        ],
      ),
    );
  }
}