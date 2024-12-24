import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/User Panel/user_login.dart'; // Replace with the correct path to your login page

class ProviderProfile extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false, // Remove all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                  'https://avatar.iran.liara.run/public'), // Placeholder image
            ),
            SizedBox(height: 20),

            // Name and Contact Info
            Text('John Doe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('+91 9876543210', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // List Tiles for Provider-Specific Options
            ListTile(
              leading: Icon(Icons.work, color: Colors.blue),
              title: Text('Manage Services'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Handle manage services
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: Text('Earnings'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Handle earnings
              },
            ),
            ListTile(
              leading: Icon(Icons.perm_media, color: Colors.blue),
              title: Text('Portfolio'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Handle portfolio
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Profile'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Handle edit profile
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blue),
              title: Text('Settings'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Handle settings
              },
            ),
            // Logout
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _logout(context), // Call the logout method
            ),
          ],
        ),
      ),
    );
  }
}
