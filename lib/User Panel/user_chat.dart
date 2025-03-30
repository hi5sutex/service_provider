import 'package:flutter/material.dart';
import 'package:service_provider/User%20Panel/chat_window.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

class UserChat extends StatefulWidget {
  @override
  _ProviderChatState createState() => _ProviderChatState();
}

class _ProviderChatState extends State<UserChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
          ),
        ),
        backgroundColor: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
        elevation: 1,
        iconTheme: IconThemeData(
          color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
        ),
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
          color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: UserTheme.shadowColor, // Matches #00000029 (Shadow)
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
                      color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    service,
                    style: TextStyle(
                      color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                    fontSize: 12,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: UserTheme.primaryColor, // Matches #060644 (Primary)
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                        fontSize: 12,
                      ),
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