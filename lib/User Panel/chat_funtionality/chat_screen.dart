import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String receiverId;
  final String senderEmail; // Add sender's email
  final String receiverEmail; // Add receiver's email

  ChatScreen({
    required this.userId,
    required this.receiverId,
    required this.senderEmail,
    required this.receiverEmail,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.userId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                } else {
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final message = snapshot.data![index];
                      return ListTile(
                        title: Text(message.message),
                        subtitle: Text(
                            "${message.senderEmail}"), // To: ${message.receiverEmail}"),
                        trailing: Text(
                          message.timestamp.toString(),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty) {
                      await _chatService.sendMessage(
                        senderId: widget.userId,
                        receiverId: widget.receiverId,
                        senderEmail: widget.senderEmail, // Pass sender's email
                        receiverEmail: widget.receiverEmail, // Pass receiver's email
                        message: _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
