import 'package:flutter/material.dart';

class UserChatWindow extends StatelessWidget {
  final int chatId;
  final String userName;

  const UserChatWindow({
    required this.chatId,
    required this.userName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://avatar.iran.liara.run/public'),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: TextStyle(color: Colors.black)),
                Text('Online', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                buildChatBubble(isSender: false, text: 'Hello, I would like to know more about your cleaning service.', time: '10:30 AM'),
                buildChatBubble(isSender: true, text: 'Sure! We offer complete home cleaning services.', time: '10:32 AM'),
              ],
            ),
          ),
          buildMessageInput(),
        ],
      ),
    );
  }

  Widget buildChatBubble({required bool isSender, required String text, required String time}) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSender ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isSender ? Colors.white : Colors.black),
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 10, color: isSender ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attachment, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
