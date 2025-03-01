import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:service_provider/Provider Panel/chat_functionality/provider_chat_screen.dart';
import 'package:service_provider/Provider%20Panel/screens/chat_screen.dart';

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
  String? currentProviderName;

  @override
  void initState() {
    super.initState();
    _getCurrentProviderDetails();
  }

  Future<void> _getCurrentProviderDetails() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentProviderEmail = currentUser.email;
      currentProviderId = currentUser.uid;

      // Fetch provider name from Firestore
      try {
        final providerDoc = await _firestore
            .collection('providers')
            .doc(currentProviderId)
            .get();

        if (providerDoc.exists) {
          setState(() {
            currentProviderName = providerDoc['name'];
          });
        }
      } catch (e) {
        print('Error fetching provider details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentProviderEmail == null || currentProviderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Client Messages', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('Please log in to view your client chats.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Messages', style: TextStyle(color: Colors.black)),
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
            return const Center(child: Text('No client chats found.'));
          }

          // Use a Set to avoid duplicates
          final Set<String> uniqueUserEmails = {};
          final List<Map<String, dynamic>> chatContacts = [];

          for (var doc in snapshot.data!.docs) {
            final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Safely access participants field
            if (!data.containsKey('participants')) {
              continue;
            }

            final List<dynamic> participants = data['participants'];

            // Find the user email (the one that's not the provider's email)
            String userEmail;
            try {
              userEmail = participants
                  .map((e) => e.toString())
                  .firstWhere((email) => email != currentProviderEmail);
            } catch (e) {
              // Skip if we can't determine the user email
              continue;
            }

            if (uniqueUserEmails.add(userEmail)) {
              // Safely handle timestamp
              Timestamp? timestamp;
              String timeAgo = 'Unknown';

              try {
                if (data.containsKey('timestamp') && data['timestamp'] != null) {
                  timestamp = data['timestamp'] as Timestamp;
                  timeAgo = _formatTimeAgo(timestamp.toDate());
                }
              } catch (e) {
                print('Error processing timestamp for document ${doc.id}: $e');
              }

              chatContacts.add({
                'email': userEmail,
                'chatRoomId': doc.id,
                'lastMessage': data['lastMessage'] ?? '',
                'timeAgo': timeAgo,
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
                  // Default to user's email instead of "Unknown User"
                  String userName = contact['email'];
                  String userId = '';

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.docs.isNotEmpty) {
                    final userDoc = userSnapshot.data!.docs.first;
                    final userData = userDoc.data() as Map<String, dynamic>;
                    // Only override email with name if name exists
                    if (userData['name'] != null) {
                      userName = userData['name'];
                    }
                    userId = userDoc.id;
                  }

                  return buildChatListItem(
                    chatRoomId: contact['chatRoomId'],
                    userId: userId,
                    userName: userName,  // This will now be either the name or email
                    userEmail: contact['email'],
                    time: contact['timeAgo'],
                    lastMessage: contact['lastMessage'] ?? '',
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
    required String time,
    required String lastMessage,
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
              backgroundColor: Color(0xFF060644),
              child: Icon(Icons.person, color: Colors.white, size: 32),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
      String userId,
      String userEmail,
      String userName,
      ) async {
    if (currentProviderId != null && currentProviderEmail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderChatScreen(
            providerId: currentProviderId!,
            userId: userId,
            providerEmail: currentProviderEmail!,
            userEmail: userEmail,
            userName: userName,
            providerName: currentProviderName ?? 'Provider',
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