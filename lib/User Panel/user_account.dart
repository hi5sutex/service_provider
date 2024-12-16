import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/User Panel/user_booking.dart'; // Create this page
import 'package:service_provider/User Panel/user_account.dart';    // Create this page
import 'package:service_provider/User Panel/user_chat.dart';
import 'package:service_provider/User Panel/user_home.dart';// Create this page



class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
  }

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 3;


  // Navigation function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the respective page
    switch (index) {
      case 0:
      // Home page doesn't need navigation, as it's already displayed
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

        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          //backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Account Page'),
        ),
        body: AccountPageBody(),
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
      ),
    );
  }
}

class AccountPageBody extends StatelessWidget {
  const AccountPageBody({Key? key}) : super(key: key);

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
                  children: const [
                    Text(
                      "Jvss",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "+91 9099586961",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.black),
                  onPressed: () {
                    // Handle edit profile action
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
            physics: NeverScrollableScrollPhysics(),
            children: [
              _MenuItem(icon: Icons.receipt_long, label: "My bookings"),
              _MenuItem(icon: Icons.devices, label: "Native devices"),
              _MenuItem(icon: Icons.headset_mic, label: "Help & support"),
            ],
          ),

          const Divider(thickness: 1, height: 0),

          // List Options
          _ListMenuItem(icon: Icons.event, label: "My Plans", onTap: () {}),
          _ListMenuItem(icon: Icons.wallet_giftcard, label: "Wallet", onTap: () {}),
          _ListMenuItem(icon: Icons.card_membership, label: "Plus membership", onTap: () {}),
          _ListMenuItem(icon: Icons.star_border, label: "My rating", onTap: () {}),
          _ListMenuItem(icon: Icons.location_on, label: "Manage addresses", onTap: () {}),
          _ListMenuItem(icon: Icons.payment, label: "Manage payment methods", onTap: () {}),
          _ListMenuItem(icon: Icons.settings, label: "Settings", onTap: () {}),
          _ListMenuItem(icon: Icons.info_outline, label: "About UC", onTap: () {}),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Add functionality here
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

  const _ListMenuItem(
      {required this.icon, required this.label, required this.onTap, Key? key})
      : super(key: key);

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
