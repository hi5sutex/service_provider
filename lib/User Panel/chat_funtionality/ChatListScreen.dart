import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_screen.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';

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

  // Default values
  static const String defaultProfileImage = 'https://avatar.iran.liara.run/public';
  static const String defaultProviderName = 'Unknown Provider';
  static const String defaultLastMessage = 'No messages yet';
  static const String defaultTime = 'Unknown';

  @override
  void initState() {
    super.initState();
    _setSystemUI();
    _getCurrentUser();
  }

  void _setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ProviderTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _getCurrentUser() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserEmail = currentUser.email ?? 'unknown@example.com';
        currentUserId = currentUser.uid;
      });
    }
  }

  @override
  void dispose() {
    _setSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: currentUserEmail == null || currentUserId == null
          ? _buildNotLoggedInView()
          : _buildChatList(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), // Curved bottom left corner
          bottomRight: Radius.circular(20), // Curved bottom right corner
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: ProviderTheme.primaryGradient,
          ),
        ),
      ),
      title: Container(
        alignment: Alignment.topLeft, // This ensures the text is centered
        child: Text(
          'Messages',
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: true, // This centers the title
      elevation: 0,
      shape: const RoundedRectangleBorder(
        // This gives the curved bottom shape
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            size: 24,
            color: ProviderTheme.onPrimaryTextColor,
          ),
          onPressed: () {
            _showOptionsMenu(context);
          },
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_chat_read,
                  color: ProviderTheme.primaryColor),
              title: const Text('Mark all as read'),
              onTap: () {
                Navigator.pop(context);
                // Implement mark all as read functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list,
                  color: ProviderTheme.primaryColor),
              title: const Text('Filter messages'),
              onTap: () {
                Navigator.pop(context);
                // Implement filter messages functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: ProviderTheme.errorTextColor),
              title: const Text('Clear chat history'),
              onTap: () {
                Navigator.pop(context);
                // Implement clear chat history functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Please log in to view your conversations',
            style: TextStyle(
              color: ProviderTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProviderTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('user_chatroom')
          .where('participants', arrayContains: currentUserEmail)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyChatsView();
        }

        return _buildChatListView(snapshot.data!.docs);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ProviderTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: ProviderTheme.errorTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading conversations',
            style: TextStyle(
              color: ProviderTheme.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please check your connection and try again.',
              style: TextStyle(
                color: ProviderTheme.secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProviderTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: ProviderTheme.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a service provider',
            style: TextStyle(
              color: ProviderTheme.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to providers list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProviderTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Find Service Providers'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListView(List<QueryDocumentSnapshot> docs) {
    final Set<String> uniqueProviderEmails = {};
    final List<Map<String, dynamic>> chatContacts = [];

    for (var doc in docs) {
      final List<dynamic> participants = doc['participants'] ?? [];
      final String providerEmail = participants
          .map((e) => e.toString())
          .firstWhere((email) => email != currentUserEmail, orElse: () => 'unknown@example.com');

      if (uniqueProviderEmails.add(providerEmail)) {
        final timestamp = doc['timestamp'] as Timestamp?;
        chatContacts.add({
          'email': providerEmail,
          'chatRoomId': doc.id ?? 'unknown_chatroom',
          'lastMessage': doc['lastMessage'] as String? ?? defaultLastMessage,
          'timestamp': timestamp,
          'unreadCount': doc['unreadCounts'] != null
              ? (doc['unreadCounts'][currentUserId] as int? ?? 0)
              : 0,
        });
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: chatContacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contact = chatContacts[index];
        return _buildChatListItem(contact);
      },
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> contact) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('providers')
          .doc(contact['chatRoomId']
          .split('-')
          .firstWhere((id) => id != currentUserId, orElse: () => ''))
          .snapshots(),
      builder: (context, userSnapshot) {
        String providerName = defaultProviderName;
        String providerId = '';
        String profileImage = defaultProfileImage;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          providerName = userData['name'] as String? ?? defaultProviderName;
          providerId = userSnapshot.data!.id ?? '';
          profileImage = userData['profileImage'] as String? ?? defaultProfileImage;
        }

        return _ChatListItem(
          chatRoomId: contact['chatRoomId'],
          providerId: providerId,
          providerName: providerName,
          providerEmail: contact['email'],
          profileImage: profileImage,
          lastMessage: contact['lastMessage'],
          time: contact['timestamp'] != null
              ? _formatTimeAgo(contact['timestamp'].toDate())
              : defaultTime,
          unreadCount: contact['unreadCount'],
          onTap: () => _navigateToChat(
            context,
            contact['chatRoomId'],
            providerId,
            contact['email'],
            providerName,
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }

  void _navigateToChat(
      BuildContext context,
      String chatRoomId,
      String receiverId,
      String receiverEmail,
      String providerName,
      ) {
    if (currentUserId == null || currentUserEmail == null) return;

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
  }
}

class _ChatListItem extends StatelessWidget {
  final String chatRoomId;
  final String providerId;
  final String providerName;
  final String providerEmail;
  final String profileImage;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chatRoomId,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    required this.profileImage,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ProviderTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ProviderTheme.shadowColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: unreadCount > 0
                ? Border.all(
                color: ProviderTheme.primaryColor.withOpacity(0.2),
                width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderRow(),
                    const SizedBox(height: 6),
                    _buildMessagePreview(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ProviderTheme.shadowColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundImage: CachedNetworkImageProvider(profileImage),
            backgroundColor: ProviderTheme.primaryColor.withOpacity(0.1),
            onBackgroundImageError: (_, __) => const Icon(Icons.person),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ProviderTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ProviderTheme.surfaceColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ProviderTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            providerName,
            style: TextStyle(
              color: ProviderTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: unreadCount > 0
                ? ProviderTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: unreadCount > 0
                  ? ProviderTheme.primaryColor
                  : ProviderTheme.secondaryTextColor,
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview() {
    return Row(
      children: [
        Expanded(
          child: Text(
            lastMessage,
            style: TextStyle(
              color: unreadCount > 0
                  ? ProviderTheme.primaryTextColor
                  : ProviderTheme.secondaryTextColor,
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (unreadCount > 0) const SizedBox(width: 8),
        if (unreadCount > 0)
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: ProviderTheme.primaryColor,
          ),
      ],
    );
  }
}