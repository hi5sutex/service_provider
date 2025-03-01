import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique chat room ID for two users
  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String senderEmail,
    required String receiverEmail,
    required String message,
  }) async {
    final chatRoomId = _getChatRoomId(senderId, receiverId);

    // Ensure the chat room document exists with participants
    await _firestore.collection('user_chatroom').doc(chatRoomId).set({
      'participants': [senderEmail, receiverEmail],
    }, SetOptions(merge: true));

    await _firestore
        .collection('user_chatroom')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages for a specific chat room
  Stream<List<ChatMessage>> getMessages(String userId, String receiverId) {
    final chatRoomId = _getChatRoomId(userId, receiverId);

    return _firestore
        .collection('user_chatroom')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data());
      }).toList();
    });
  }
}
