import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/theme.dart';

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final Timestamp timestamp;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;

  const ChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverEmail,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatMessage = ChatMessage(
      senderId: currentUser.uid,
      receiverId: widget.receiverId,
      senderEmail: currentUser.email ?? '',
      receiverEmail: widget.receiverEmail,
      message: _messageController.text.trim(),
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance.collection('messages').add(chatMessage.toMap());

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        backgroundColor: ProviderTheme.primaryColor, // Matches #060644 (Primary)
        title: Text(
          widget.receiverEmail,
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('senderId', whereIn: [currentUserId, widget.receiverId])
                  .where('receiverId', whereIn: [currentUserId, widget.receiverId])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(
                        color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!.docs
                    .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isMe
                                ? ProviderTheme.primaryColor // Matches #060644 (Primary)
                                : ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message.message,
                            style: TextStyle(
                              color: isMe
                                  ? ProviderTheme.onPrimaryTextColor // Matches #FFFFFF (On Primary Text)
                                  : ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
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
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}