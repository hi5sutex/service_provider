import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_message.dart';

class ChatService {
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${ids[0]}-${ids[1]}'; // Using hyphen as separator
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String senderEmail,
    required String receiverEmail,
    required String message,
  }) async {
    final chatRoomId = getChatRoomId(senderId, receiverId);
    final timestamp = Timestamp.now();

    final chatMessage = ChatMessage(
      senderId: senderId,
      receiverId: receiverId,
      senderEmail: senderEmail,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
      isRead: false,
    );

    try {
      // Fetch the current chat room document
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('user_chatroom')
          .doc(chatRoomId)
          .get();

      Map<String, dynamic> unreadCounts = chatRoomDoc.exists
          ? (chatRoomDoc.data()!['unreadCounts'] ?? {})
          : {};

      // Increment unread count for the receiver
      unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;

      // Update the chat room document with the new message and metadata
      await FirebaseFirestore.instance.collection('user_chatroom').doc(chatRoomId).set({
        'lastMessage': message,
        'timestamp': timestamp,
        'participants': [senderEmail, receiverEmail],
        'unreadCounts': unreadCounts,
        'messages': FieldValue.arrayUnion([chatMessage.toMap()]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Stream<List<ChatMessage>> getMessages(String userId, String otherUserId) {
    final chatRoomId = getChatRoomId(userId, otherUserId);
    return FirebaseFirestore.instance
        .collection('user_chatroom')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()!['messages'] != null) {
        final messages = snapshot.data()!['messages'] as List<dynamic>;
        return messages
            .map((msg) => ChatMessage.fromMap(msg as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return [];
    });
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId, String userEmail) async {
    try {
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('user_chatroom')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      List<dynamic> messages = chatRoomDoc.data()!['messages'] ?? [];
      List<Map<String, dynamic>> updatedMessages = messages.map((msg) {
        final message = ChatMessage.fromMap(msg as Map<String, dynamic>);
        if (message.receiverEmail == userEmail && !message.isRead) {
          return ChatMessage(
            senderId: message.senderId,
            receiverId: message.receiverId,
            senderEmail: message.senderEmail,
            receiverEmail: message.receiverEmail,
            message: message.message,
            timestamp: message.timestamp,
            isRead: true,
          ).toMap();
        }
        return msg as Map<String, dynamic>;
      }).toList();

      await FirebaseFirestore.instance.collection('user_chatroom').doc(chatRoomId).update({
        'messages': updatedMessages,
        'unreadCounts': {userId: 0},
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}