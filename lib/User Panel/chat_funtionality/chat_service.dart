import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique chat room ID based on user and provider IDs
  String _getChatRoomId(String userId, String receiverId) {
    return userId.compareTo(receiverId) < 0
        ? '$userId-$receiverId'
        : '$receiverId-$userId';
  }

  // Send a message and create/update chatroom
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String senderEmail,
    required String receiverEmail,
    required String message,
  }) async {
    final chatRoomId = _getChatRoomId(senderId, receiverId);
    final messageData = ChatMessage(
      senderId: senderId,
      receiverId: receiverId,
      senderEmail: senderEmail,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: Timestamp.now(),
    ).toMap();

    // Add message to the messages subcollection
    await _firestore
        .collection('user_chatroom')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      ...messageData,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
    });

    // Create or update chatroom metadata
    await _firestore.collection('user_chatroom').doc(chatRoomId).set({
      'participants': [senderEmail, receiverEmail],
      'lastMessage': message,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Retrieve messages for the chatroom
  Stream<List<ChatMessage>> getMessages(String userId, String receiverId) {
    final chatRoomId = _getChatRoomId(userId, receiverId);
    return _firestore
        .collection('user_chatroom')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return ChatMessage.fromMap(doc.data());
    }).toList());
  }
}