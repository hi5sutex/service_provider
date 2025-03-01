import 'package:flutter/material.dart';
import 'package:service_provider/User Panel/chat_window.dart';

class UserChat extends StatefulWidget {
  @override
  _ProviderChatState createState() => _ProviderChatState();
}

class _ProviderChatState extends State<UserChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          buildChatListItem(
            chatId: 1,
            userName: 'John Doe',
            service: 'House Cleaning Service',
            time: '2m ago',
            unreadCount: 2,
          ),
          buildChatListItem(
            chatId: 2,
            userName: 'Sarah Smith',
            service: 'Plumbing Service',
            time: '1h ago',
            unreadCount: 0,
          ),
        ],
      ),
    );
  }

  Widget buildChatListItem({
    required int chatId,
    required String userName,
    required String service,
    required String time,
    int unreadCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to ChatWindowScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatWindow(
              chatId: chatId,
              userName: userName,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                'https://avatar.iran.liara.run/public',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    service,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF060644),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// class UserChat {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Add a chat message to a user's chat history
//   Future<void> addUserChat({
//     required String userId,
//     required ChatMessage message,
//   }) async {
//     await _firestore
//         .collection('user_chats')
//         .doc(userId)
//         .collection('messages')
//         .add(message.toMap());
//   }
//
//   // Get all chat messages for a specific user
//   Stream<List<ChatMessage>> getUserChats(String userId) {
//     return _firestore
//         .collection('user_chats')
//         .doc(userId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return ChatMessage.fromMap(doc.data());
//       }).toList();
//     });
//   }
//
//   // Get chat messages between two specific users
//   Stream<List<ChatMessage>> getChatBetweenUsers({
//     required String userId,
//     required String otherUserId,
//   }) {
//     return _firestore
//         .collection('user_chats')
//         .doc(userId)
//         .collection('messages')
//         .where('senderId', whereIn: [userId, otherUserId])
//         .where('receiverId', whereIn: [userId, otherUserId])
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return ChatMessage.fromMap(doc.data());
//       }).toList();
//     });
//   }
// }
