import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_screen.dart';
import 'package:service_provider/theme.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (currentUserEmail == null || currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Messages',
            style: TextStyle(
              color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              fontSize: screenWidth * 0.05,
            ),
          ),
          backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
          elevation: 1,
          iconTheme: IconThemeData(
            color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view your chats.',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
            ),
          ),
        ),
        backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
        elevation: 1,
        iconTheme: IconThemeData(
          color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
        ),
      ),
      backgroundColor: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('user_chatroom')
            .where('participants', arrayContains: currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: ProviderTheme.errorTextColor, // Matches #D32F2F (Error Text)
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No chats found.',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
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
                'unreadCount': 0,
              });
            }
          }

          return ListView(
            padding: EdgeInsets.all(screenWidth * 0.04),
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
                    serviceName = 'Service';
                  }

                  return buildChatListItem(
                    chatRoomId: contact['chatRoomId'],
                    providerId: providerId,
                    providerName: providerName,
                    providerEmail: contact['email'],
                    lastMessage: contact['lastMessage'],
                    time: contact['timestamp'] != null
                        ? _formatTimeAgo(contact['timestamp'].toDate())
                        : 'Unknown',
                    unreadCount: contact['unreadCount'],
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
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
    required String lastMessage,
    required String time,
    required double screenWidth,
    required double screenHeight,
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
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor.withOpacity(0.1), // Matches #000000 with opacity
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: screenWidth * 0.075,
              backgroundImage:
              const NetworkImage('https://avatar.iran.liara.run/public'),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                      color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                      fontSize: screenWidth * 0.035,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.01),
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                        fontSize: screenWidth * 0.03,
                      ),
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