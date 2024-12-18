import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/user_booking.dart'; // Add your actual Booking Page
import 'package:service_provider/User Panel/user_chat.dart'; // Add your actual Chat Page
import 'package:service_provider/User Panel/user_home.dart'; // Add your actual Home Page

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 3;
  String userName = "Loading...";
  String userPhone = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch user data from Firestore
  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Make sure your collection name is 'users'
          .doc(user.uid) // Retrieve document using user's UID
          .get();

      setState(() {
        userName = userDoc['name'] ?? "No Name";
        userPhone = userDoc['phone'] ?? "No Phone Number";
      });
    }
  }

  // Navigation function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BookingPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage()),
        );
        break;
      case 3:
        // Do nothing, already on Account Page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: AccountPageBody(userName: userName, userPhone: userPhone),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AccountPageBody extends StatelessWidget {
  final String userName;
  final String userPhone;

  const AccountPageBody({
    Key? key,
    required this.userName,
    required this.userPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section: User Name and Mobile
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "+91 $userPhone",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () {
                    // Add Edit Profile functionality here
                  },
                )
              ],
            ),
          ),
          const Divider(thickness: 1, height: 0),

          // Top Menu Options
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _MenuItem(icon: Icons.receipt_long, label: "My bookings"),
              _MenuItem(icon: Icons.devices, label: "Native devices"),
              _MenuItem(icon: Icons.headset_mic, label: "Help & support"),
            ],
          ),
          const Divider(thickness: 1, height: 0),

          // List Options
          _ListMenuItem(icon: Icons.event, label: "My Plans", onTap: () {}),
          _ListMenuItem(
              icon: Icons.wallet_giftcard, label: "Wallet", onTap: () {}),
          _ListMenuItem(
              icon: Icons.card_membership,
              label: "Plus membership",
              onTap: () {}),
          _ListMenuItem(
              icon: Icons.star_border, label: "My rating", onTap: () {}),
          _ListMenuItem(
              icon: Icons.location_on, label: "Manage addresses", onTap: () {}),
          _ListMenuItem(
              icon: Icons.payment,
              label: "Manage payment methods",
              onTap: () {}),
          _ListMenuItem(icon: Icons.settings, label: "Settings", onTap: () {}),
          _ListMenuItem(
              icon: Icons.info_outline, label: "About UC", onTap: () {}),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label, Key? key})
      : super(key: key);

  void _handleTap(BuildContext context) {
    switch (label) {
      case "My bookings":
        // Navigate to bookings page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingPage()),
        );
        break;
      case "Native devices":
        // You can add navigation or show a dialog for native devices
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Native Devices feature coming soon'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case "Help & support":
        // Navigate to help and support page or show support options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Help & Support feature coming soon'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      default:
        print('No action defined for $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ListMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ListMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
    );
  }
}
