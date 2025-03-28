import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/theme.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:service_provider/Provider%20Panel/screens/chat/chat_screen.dart';


class ProviderChatListScreen extends StatefulWidget {
  const ProviderChatListScreen({Key? key}) : super(key: key);

  @override
  _ProviderChatListScreenState createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String? currentProviderEmail;
  String? currentProviderId;
  String? currentProviderName;
  List<Map<String, dynamic>> _filteredChatContacts = [];
  List<Map<String, dynamic>> _allChatContacts = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      currentProviderEmail = currentUser.email;
      currentProviderId = currentUser.uid;
      _fetchProviderName();
    }
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  Future<void> _fetchProviderName() async {
    if (currentProviderId != null) {
      final providerDoc = await _firestore.collection('providers').doc(currentProviderId).get();
      if (providerDoc.exists) {
        setState(() {
          currentProviderName = providerDoc['name'] ?? 'Unknown Provider';
        });
      }
    }
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChatContacts = List.from(_allChatContacts);
      } else {
        _filteredChatContacts = _allChatContacts
            .where((contact) =>
        contact['userName'].toLowerCase().contains(query) ||
            contact['email'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _allChatContacts.clear();
      _filteredChatContacts.clear();
    });
    await Future.delayed(const Duration(milliseconds: 1000));
  }


  @override
  Widget build(BuildContext context) {
    if (currentProviderEmail == null || currentProviderId == null) {
      return Scaffold(
        backgroundColor: ProviderTheme.backgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ProviderTheme.primaryGradient,
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
        body: Center(
          child: Text(
            'Please log in to view your chats.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
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
        title: const Text('Messages'),
        centerTitle: false,
        elevation: 4,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('user_chatroom')
                  .where('participants', arrayContains: currentProviderEmail)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No chats found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final Set<String> uniqueUserEmails = {};
                _allChatContacts.clear();

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

                    _allChatContacts.add({
                      'email': userEmail,
                      'chatRoomId': doc.id,
                      'lastMessage': doc['lastMessage'] ?? 'No messages yet',
                      'timestamp': timestamp,
                      'unreadCount': doc['unreadCounts'] != null
                          ? (doc['unreadCounts'][currentProviderId] ?? 0)
                          : 0,
                    });
                  }
                }

                _filteredChatContacts = _searchController.text.isEmpty
                    ? List.from(_allChatContacts)
                    : _allChatContacts;

                if (_filteredChatContacts.isEmpty) {
                  return Center(
                    child: Text(
                      'No chats match your search.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: ProviderTheme.accentColor,
                  backgroundColor: ProviderTheme.surfaceColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: _filteredChatContacts.map((contact) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(contact['chatRoomId'].split('-').firstWhere((id) => id != currentProviderId))
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          String userName = 'Unknown User';
                          String userId = '';
                          String profileImage = 'https://avatar.iran.liara.run/public';

                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userDoc = userSnapshot.data!;
                            userName = userDoc['name'] ?? 'Unknown User';
                            userId = userDoc.id;
                            profileImage = userDoc['profileImage'] ?? profileImage;
                          }

                          return buildChatListItem(
                            chatRoomId: contact['chatRoomId'],
                            userId: userId,
                            userName: userName,
                            userEmail: contact['email'],
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChatListItem({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String userEmail,
    required String profileImage,
    required String lastMessage,
    required String time,
    required int unreadCount,
  }) {
    return GestureDetector(
      onTap: () => _navigateToChat(context, chatRoomId, userId, userEmail, userName),
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
            CircleAvatar(
              radius: 30,
              backgroundImage: CachedNetworkImageProvider(profileImage),
              backgroundColor: ProviderTheme.primaryColor.withOpacity(0.1),
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
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ProviderTheme.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(7),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ProviderTheme.secondaryTextColor,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      String userName,
      ) async {
    if (currentProviderId != null && currentProviderEmail != null && currentProviderName != null) {
      final parts = chatRoomId.split('-');
      final chatReceiverId = parts[0] == currentProviderId ? parts[1] : parts[0];
      final finalReceiverId = receiverId.isEmpty ? chatReceiverId : receiverId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderChatScreen(
            userId: finalReceiverId,
            providerId: currentProviderId!,
            userName: userName,
            providerEmail: currentProviderEmail!,
            userEmail: receiverEmail,
            providerName: currentProviderName!,
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