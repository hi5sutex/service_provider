// home_page.dart
import 'package:flutter/material.dart';

// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages for each tab
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Welcome to the Home Page!', style: TextStyle(fontSize: 20))),
    Center(child: Text('Booking Page', style: TextStyle(fontSize: 20))),
    Center(child: Text('Chat Page', style: TextStyle(fontSize: 20))),
    Center(child: Text('Account Page', style: TextStyle(fontSize: 20))),
  ];

  // Update the selected index when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Home'
              : _selectedIndex == 1
              ? 'Booking'
              : _selectedIndex == 2
              ? 'Chat'
              : 'Account',
        ),
      ),
      body: _pages[_selectedIndex], // Show the corresponding page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure all icons are visible
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
        currentIndex: _selectedIndex, // Highlight the selected tab
        selectedItemColor: Colors.blue, // Active tab color
        unselectedItemColor: Colors.grey, // Inactive tab color
        onTap: _onItemTapped, // Handle tab changes
      ),
    );
  }
}
