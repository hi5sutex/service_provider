import 'package:flutter/material.dart';

class UserBooking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmed Bookings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar with reduced height
            TextField(
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12), // Reduced space

            // Filters Section (Sort Bar) with reduced height



            // Booking Cards with adjusted padding
            Expanded(
              child: ListView(
                children: [
                  BookingCard(
                    serviceName: 'Plumbing',
                    dateTime: '25th Oct, 10:00 AM',
                    userName: 'John Smith',
                    userImage: 'https://avatar.iran.liara.run/public',
                    location: '123 Main Street, Springfield',
                    price: '\$150',
                  ),
                  BookingCard(
                    serviceName: 'Cleaning',
                    dateTime: '26th Oct, 2:00 PM',
                    userName: 'Alice Brown',
                    userImage: 'https://avatar.iran.liara.run/public',
                    location: '456 Elm Street, Metropolis',
                    price: '\$100',
                  ),
                ],
              ),
            ),

            // No Bookings Section (Hidden if bookings are available)
            Visibility(
              visible: false, // Change to true if no bookings
              child: Column(
                children: [
                  Image.network(
                    'https://via.placeholder.com/200',
                    height: 200,
                  ),
                  Text(
                    'No Bookings Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Book New Service Button with reduced height
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45), // Reduced height
                backgroundColor: Color(0xFF060644),
              ),
              child: Text('Book New Service', style: TextStyle(fontSize: 14,color: Color(
                  0xFFFFFFFF))),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String serviceName;
  final String dateTime;
  final String userName;
  final String userImage;
  final String location;
  final String price;

  BookingCard({
    required this.serviceName,
    required this.dateTime,
    required this.userName,
    required this.userImage,
    required this.location,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6), // Reduced space
            Text('Date & Time: $dateTime', style: TextStyle(fontSize: 12)),
            SizedBox(height: 6), // Reduced space
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userImage),
                  radius: 20, // Reduced size
                ),
                SizedBox(width: 8),
                Text(userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 6), // Reduced space
            Text('Location: $location', style: TextStyle(fontSize: 12)),
            SizedBox(height: 6), // Reduced space
            Text('Price: $price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 12), // Reduced space
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('View Details', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Reschedule', style: TextStyle(color: Color(0xFF060644), fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: UserBooking()));
