// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../User Panel/chat_funtionality/chat_screen.dart';
// import 'chat_screen.dart';
//
// class AllUserChatList extends StatelessWidget {
//   final String userId;
//   final String userEmail;
//
//   AllUserChatList({required this.userId, required this.userEmail});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Your Chats'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('user_chatroom')
//             .where('participants', arrayContains: userEmail)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No chats found.'));
//           } else {
//             return ListView.builder(
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 var chatRoom = snapshot.data!.docs[index];
//                 var participants = chatRoom['participants'] as List;
//                 var otherUserEmail = participants.firstWhere((email) => email != userEmail);
//
//                 return ListTile(
//                   title: Text(otherUserEmail),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatScreen(
//                           userId: userId,
//                           receiverId: chatRoom.id,
//                           senderEmail: userEmail,
//                           receiverEmail: otherUserEmail,
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
//
