import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String chatRoomId = '';

  @override
  void initState() {
    super.initState();
    _setupChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupChatRoom() async {
    // Create a sorted ID to ensure consistency
    List<String> ids = [widget.providerId, widget.userId];
    ids.sort(); // Sort to ensure the same ID regardless of who initiates
    chatRoomId = '${ids[0]}-${ids[1]}';

    // Check if the chatroom exists, if not create it
    final chatDoc = await _firestore.collection('user_chatroom').doc(chatRoomId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('user_chatroom').doc(chatRoomId).set({
        'participants': [widget.providerEmail, widget.userEmail],
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Get the current timestamp
    final timestamp = Timestamp.now();

    try {
      // Create a unique message ID
      final messageId = _firestore
          .collection('user_chatroom')
          .doc(chatRoomId)
          .collection('messages')
          .doc()
          .id;

      // Save the message
      await _firestore
          .collection('user_chatroom')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'text': messageText,
        'senderId': widget.providerId,
        'senderEmail': widget.providerEmail,
        'senderName': widget.providerName,
        'timestamp': timestamp,
        'isRead': false,
      });

      // Update the chat room with last message and timestamp
      await _firestore.collection('user_chatroom').doc(chatRoomId).update({
        'lastMessage': messageText,
        'timestamp': timestamp,
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            Text(
              widget.userEmail,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('user_chatroom')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSend a message to start the conversation.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // Auto-scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderEmail'] == widget.providerEmail;
                    final timestamp = message['timestamp'] as Timestamp;
                    final messageTime = DateFormat('h:mm a').format(timestamp.toDate());

                    return _buildMessageItem(message['text'], isMe, messageTime);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF060644),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(String message, bool isMe, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF060644) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}