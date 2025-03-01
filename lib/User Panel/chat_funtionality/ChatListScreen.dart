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
          title: const Text('Chat List'),
          backgroundColor: const Color(0xFF060644),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your chats.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        backgroundColor: const Color(0xFF060644),
        foregroundColor: Colors.white,
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

          // Use a Set to avoid duplicate provider emails
          final Set<String> uniqueProviderEmails = {};
          final List<Map<String, dynamic>> chatContacts = [];

          for (var doc in snapshot.data!.docs) {
            final List<dynamic> participants = doc['participants'];
            final String providerEmail = participants
                .map((e) => e.toString())
                .firstWhere((email) => email != currentUserEmail);

            if (uniqueProviderEmails.add(providerEmail)) {
              chatContacts.add({
                'email': providerEmail,
                'chatRoomId': doc.id, // Optional: store chatroom ID if needed
              });
            }
          }

          return ListView.builder(
            itemCount: chatContacts.length,
            itemBuilder: (context, index) {
              final providerEmail = chatContacts[index]['email'];

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('providers')
                    .where('email', isEqualTo: providerEmail)
                    .snapshots(),
                builder: (context, providerSnapshot) {
                  if (providerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    );
                  }

                  if (providerSnapshot.hasError ||
                      !providerSnapshot.hasData ||
                      providerSnapshot.data!.docs.isEmpty) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      title: const Text('Unknown Provider'),
                      subtitle: Text(providerEmail),
                      onTap: () => _navigateToChat(context, null, providerEmail),
                    );
                  }

                  final providerDoc = providerSnapshot.data!.docs.first;
                  final providerId = providerDoc.id;
                  final providerName = providerDoc['name'] as String? ?? 'Unknown Provider';
                  final lastMessage = snapshot.data!.docs[index]['lastMessage'] as String? ?? 'No messages';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    title: Text(providerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(providerEmail),
                        Text(
                          'Last: $lastMessage',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    onTap: () => _navigateToChat(context, providerId, providerEmail),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, String? receiverId, String receiverEmail) {
    if (currentUserId != null && currentUserEmail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: currentUserId!,
            receiverId: receiverId ?? '',
            senderEmail: currentUserEmail!,
            receiverEmail: receiverEmail,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to view chats.')),
      );
    }
  }
}