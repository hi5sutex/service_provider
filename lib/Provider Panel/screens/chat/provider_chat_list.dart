import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/chat_funtionality/chat_screen.dart'; // Adjust import as needed

class ProviderChatListScreen extends StatefulWidget {
  const ProviderChatListScreen({Key? key}) : super(key: key);

  @override
  _ProviderChatListScreenState createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? currentProviderEmail;
  String? currentProviderId;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentProviderEmail = currentUser.email;
      currentProviderId = currentUser.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentProviderEmail == null || currentProviderId == null) {
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
            .where('participants', arrayContains: currentProviderEmail)
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

          final Set<String> uniqueUserEmails = {};
          final List<Map<String, dynamic>> chatContacts = [];

          for (var doc in snapshot.data!.docs) {
            final List<dynamic> participants = doc['participants'];
            final String userEmail = participants
                .map((e) => e.toString())
                .firstWhere((email) => email != currentProviderEmail);

            if (uniqueUserEmails.add(userEmail)) {
              final timestamp = doc['timestamp'] as Timestamp?;
              final String timeAgo = timestamp != null
                  ? _formatTimeAgo(timestamp.toDate())
                  : 'Unknown';
              chatContacts.add({
                'email': userEmail,
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
                    .collection('users')
                    .where('email', isEqualTo: contact['email'])
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String userName = 'Unknown User';
                  String userId = '';

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.docs.isNotEmpty) {
                    final userDoc = userSnapshot.data!.docs.first;
                    userName = userDoc['name'] ?? 'Unknown User';
                    userId = userDoc.id;
                  }

                  return buildChatListItem(
                    chatRoomId: contact['chatRoomId'],
                    userId: userId,
                    userName: userName,
                    userEmail: contact['email'],
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
    required String userId,
    required String userName,
    required String userEmail,
    required String lastMessage, // Added lastMessage parameter
    required String time,
    int unreadCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        _navigateToChat(
          context,
          chatRoomId,
          userId,
          userEmail,
          userName,
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
                    userName,
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
      String userName,
      ) async {
    if (currentProviderId != null && currentProviderEmail != null) {
      final parts = chatRoomId.split('-');
      final chatReceiverId = parts[0] == currentProviderId ? parts[1] : parts[0];
      final finalReceiverId = receiverId.isEmpty ? chatReceiverId : receiverId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: currentProviderId!,
            receiverId: finalReceiverId,
            senderEmail: currentProviderEmail!,
            receiverEmail: receiverEmail,
            providerName: userName,
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