import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/user_login.dart'; // Replace with the correct path
import 'package:service_provider/Provider Panel/screens/edit_profile.dart'; // Replace with the correct path to EditProfile()
import 'package:service_provider/Provider Panel/screens/manage_services.dart'; // Replace with the correct path to ManageServices()
import 'package:service_provider/Provider Panel/screens/earnings.dart'; // Replace with the correct path to Earnings()
import 'package:service_provider/Provider Panel/screens/portfolio.dart'; // Replace with the correct path to Portfolio()
import 'package:service_provider/Provider Panel/screens/provider_settings.dart'; // Replace with the correct path to Settings()

class ProviderProfile extends StatelessWidget {
  final String providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed. Please try again.")),
      );
    }
  }

  Future<Map<String, dynamic>> _getProviderInfo() async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(providerId)
        .get();
    return providerDoc.data() as Map<String, dynamic>;
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getProviderInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading provider info.'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No provider data found.'));
          } else {
            var providerInfo = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            providerInfo['profileImage'] ??
                                'https://avatar.iran.liara.run/public',
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          providerInfo['name'] ?? 'John Doe',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          providerInfo['email'] ?? 'example@example.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildOptionList(context),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOptionList(BuildContext context) {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.work,
          title: 'Manage Services',
          onTap: () => _navigateTo(context, ManageServices()),
        ),
        _buildListTile(
          icon: Icons.account_balance_wallet,
          title: 'Earnings',
          onTap: () => _navigateTo(context, Earnings()),
        ),
        _buildListTile(
          icon: Icons.perm_media,
          title: 'Portfolio',
          onTap: () => _navigateTo(context, Portfolio()),
        ),
        _buildListTile(
          icon: Icons.edit,
          title: 'Edit Profile',
          onTap: () => _navigateTo(context, EditProfile()),
        ),
        _buildListTile(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () => _navigateTo(context, ProviderSettings()),
        ),
        _buildListTile(
          icon: Icons.logout,
          title: 'Logout',
          iconColor: Colors.red,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
