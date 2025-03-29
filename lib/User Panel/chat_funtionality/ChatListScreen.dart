import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_screen.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentUserEmail = currentUser.email;
      currentUserId = currentUser.uid;
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail == null || currentUserId == null) {
      return Scaffold(
        backgroundColor: ProviderTheme.backgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ProviderTheme.primaryGradient,
            ),
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: FaIcon(
              FontAwesomeIcons.solidComment,
              color: ProviderTheme.accentColor,
              size: 28,
            ),
          ),
          title: Text(
            'Messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ProviderTheme.onPrimaryTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          elevation: 4,
          shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
        ),
        body: const Center(child: Text('Please log in to view your chats.')),
      );
    }

    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient,
          ),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: FaIcon(
            FontAwesomeIcons.solidComment,
            color: ProviderTheme.accentColor,
            size: 28,
          ),
        ),
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ProviderTheme.onPrimaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 4,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('user_chatroom')
            .where('participants', arrayContains: currentUserEmail)
            .orderBy('timestamp', descending: true)
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
                'unreadCount': doc['unreadCounts'] != null
                    ? (doc['unreadCounts'][currentUserId] ?? 0)
                    : 0,
              });
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: chatContacts.map((contact) {
              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('providers')
                    .doc(contact['chatRoomId'].split('-').firstWhere((id) => id != currentUserId))
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String providerName = 'Unknown Provider';
                  String providerId = '';
                  String profileImage = 'https://avatar.iran.liara.run/public';

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    providerName = userData['name'] ?? 'Unknown Provider';
                    providerId = userSnapshot.data!.id;
                    profileImage = userData['profileImage'] ?? profileImage;
                  }

                  return buildChatListItem(
                    chatRoomId: contact['chatRoomId'],
                    providerId: providerId,
                    providerName: providerName,
                    providerEmail: contact['email'],
                    profileImage: profileImage,
                    lastMessage: contact['lastMessage'],
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
    required String profileImage,
    required String lastMessage,
    required String time,
    required int unreadCount,
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
          color: ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(profileImage),
                  backgroundColor: ProviderTheme.primaryColor.withOpacity(0.1),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ProviderTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: ProviderTheme.surfaceColor, width: 2),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: ProviderTheme.onPrimaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        providerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ProviderTheme.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ProviderTheme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: unreadCount > 0
                          ? ProviderTheme.primaryTextColor
                          : ProviderTheme.secondaryTextColor,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
            receiverName: providerName,
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

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}