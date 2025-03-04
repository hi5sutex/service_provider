import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/chat_funtionality/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? currentUserEmail;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentUserEmail = currentUser.email;
      currentUserId = currentUser.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail == null || currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('Please log in to view your chats.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('user_chatroom')
            .where('participants', arrayContains: currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }

          final Set<String> uniqueProviderEmails = {};
          final List<Map<String, dynamic>> chatContacts = [];

          for (var doc in snapshot.data!.docs) {
            final List<dynamic> participants = doc['participants'];
            final String providerEmail = participants
                .map((e) => e.toString())
                .firstWhere((email) => email != currentUserEmail);

            if (uniqueProviderEmails.add(providerEmail)) {
              final timestamp = doc['timestamp'] as Timestamp?;
              final String timeAgo = timestamp != null
                  ? _formatTimeAgo(timestamp.toDate())
                  : 'Unknown';
              chatContacts.add({
                'email': providerEmail,
                'chatRoomId': doc.id,
                'lastMessage': doc['lastMessage'] ?? 'No messages yet',
                'timestamp': timestamp,
                'unreadCount': 0, // Placeholder, implement unread logic if needed
              });
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: chatContacts.map((contact) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('providers')
                    .where('email', isEqualTo: contact['email'])
                    .snapshots(),
                builder: (context, providerSnapshot) {
                  String providerName = 'Unknown Provider';
                  String serviceName = 'Unknown Service';
                  String providerId = '';

                  if (providerSnapshot.hasData &&
                      providerSnapshot.data!.docs.isNotEmpty) {
                    final providerDoc = providerSnapshot.data!.docs.first;
                    providerName = providerDoc['name'] ?? 'Unknown Provider';
                    providerId = providerDoc.id;
                    serviceName = 'Service'; // Replace with actual service fetch if available
                  }

                  return buildChatListItem(
                    chatRoomId: contact['chatRoomId'],
                    providerId: providerId,
                    providerName: providerName,
                    providerEmail: contact['email'],
                    lastMessage: contact['lastMessage'], // Pass lastMessage
                    time: contact['timestamp'] != null
                        ? _formatTimeAgo(contact['timestamp'].toDate())
                        : 'Unknown',
                    unreadCount: contact['unreadCount'],
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildChatListItem({
    required String chatRoomId,
    required String providerId,
    required String providerName,
    required String providerEmail,
    required String lastMessage, // Added lastMessage parameter
    required String time,
    int unreadCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        _navigateToChat(
          context,
          chatRoomId,
          providerId,
          providerEmail,
          providerName,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://avatar.iran.liara.run/public'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage, // Display the last message
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1, // Limit to one line
                    overflow: TextOverflow.ellipsis, // Add ellipsis if too long
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF060644),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(
      BuildContext context,
      String chatRoomId,
      String receiverId,
      String receiverEmail,
      String providerName,
      ) async {
    if (currentUserId != null && currentUserEmail != null) {
      final parts = chatRoomId.split('-');
      final chatReceiverId = parts[0] == currentUserId ? parts[1] : parts[0];
      final finalReceiverId = receiverId.isEmpty ? chatReceiverId : receiverId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: currentUserId!,
            receiverId: finalReceiverId,
            senderEmail: currentUserEmail!,
            receiverEmail: receiverEmail,
            providerName: providerName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to view chats.')),
      );
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}