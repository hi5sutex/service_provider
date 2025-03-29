import 'package:flutter/material.dart';
import 'package:service_provider/theme.dart';
// import 'theme.dart'; // Import ProviderTheme

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
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      appBar: AppBar(
        // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
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
                Text(
                  userName,
                  style: TextStyle(
                    color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: ProviderTheme.successColor, // Matches #388E3C (Success)
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                buildChatBubble(
                  isSender: false,
                  text: 'Hello, I would like to know more about your cleaning service.',
                  time: '10:30 AM',
                ),
                buildChatBubble(
                  isSender: true,
                  text: 'Sure! We offer complete home cleaning services.',
                  time: '10:32 AM',
                ),
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
          color: isSender
              ? ProviderTheme.primaryColor // Matches #060644 (Primary)
              : ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor, // Matches #00000029 (Shadow)
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
              style: TextStyle(
                color: isSender
                    ? ProviderTheme.onPrimaryTextColor // Matches #FFFFFF (On Primary Text)
                    : ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
              ),
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isSender
                    ? ProviderTheme.onPrimaryTextColor.withOpacity(0.7) // Matches #FFFFFF with opacity
                    : ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attachment,
              color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
            ),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                // Border, hint style, etc., are set by ProviderTheme.inputDecorationTheme
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}