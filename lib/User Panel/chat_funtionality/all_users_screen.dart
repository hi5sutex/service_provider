import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/User Panel/chat_funtionality/chat_screen.dart';
class AllUsersScreen extends StatefulWidget {
  @override
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid; // Get the current user's ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users and Providers'),
        backgroundColor: Color(0xFF060644),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (usersSnapshot.hasError) {
            return Center(
              child: Text('Error loading users'),
            );
          }

          final users = usersSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('providers').snapshots(),
            builder: (context, providersSnapshot) {
              if (providersSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (providersSnapshot.hasError) {
                return Center(
                  child: Text('Error loading providers'),
                );
              }

              final providers = providersSnapshot.data!.docs;

              // Combine users and providers into a single list
              final allUsers = [...users, ...providers];

              return ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final userId = user.id;
                  final userName = user['name'] as String? ?? 'Unknown User';
                  final userEmail = user['email'] as String? ?? 'No Email';

                  // Don't show the current user in the list
                  if (userId == currentUserId) {
                    return SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    ),
                    title: Text(userName),
                    subtitle: Text(userEmail),
                    onTap: () {
                      final currentUser = _auth.currentUser;
                      if (currentUser != null && currentUser.email != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              userId: currentUserId!,
                              receiverId: userId,
                              senderEmail: currentUser.email!,
                              receiverEmail: userEmail,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You must be logged in to send messages.')),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
