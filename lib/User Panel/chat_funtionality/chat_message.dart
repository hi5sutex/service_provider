class ChatMessage {
  final String senderId;
  final String receiverId;
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
  });

  // Convert ChatMessage to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
    };
  }

  // Create a ChatMessage from a Firestore Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      senderEmail: map['senderEmail'],
      receiverEmail: map['receiverEmail'],
      message: map['message'],
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(), // Handle null timestamp
    );
  }
}
