import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedFilter = 'All'; // Default filter
  final List<String> _filters = ['All', 'Pending', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view earnings')),
      );
    }
    final String providerId = user.uid; // Assuming provider uses their auth UID

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Earnings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF060644),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              items: _filters.map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Filter Earnings',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Earnings List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('earnings')
                  .doc(providerId)
                  .collection('records')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No earnings found'));
                }

                List<QueryDocumentSnapshot> earningsDocs = snapshot.data!.docs;

                // Apply filter
                if (_selectedFilter != 'All') {
                  earningsDocs = earningsDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['earningStatus'] == _selectedFilter;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: earningsDocs.length,
                  itemBuilder: (context, index) {
                    final earningData = earningsDocs[index].data() as Map<String, dynamic>;
                    final String bookingId = earningsDocs[index].id;

                    return EarningsCard(
                      earningData: earningData,
                      bookingId: bookingId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EarningsCard extends StatelessWidget {
  final Map<String, dynamic> earningData;
  final String bookingId;

  const EarningsCard({
    required this.earningData,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('bookings').doc(bookingId).get(),
      builder: (context, snapshot) {
        String serviceName = 'Loading...';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
          final String serviceId = bookingData?['serviceId'] ?? 'Unknown';
          // Fetch service name using serviceId (assuming a services collection)
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('services').doc(serviceId).get(),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.done && serviceSnapshot.hasData) {
                final serviceData = serviceSnapshot.data!.data() as Map<String, dynamic>?;
                serviceName = serviceData?['name'] ?? 'Unknown Service';
              }
              return _buildCard(context, serviceName);
            },
          );
        }
        return _buildCard(context, serviceName);
      },
    );
  }

  Widget _buildCard(BuildContext context, String serviceName) {
    final double serviceAmount = (earningData['serviceAmount'] as num?)?.toDouble() ?? 0.0;
    final double taxAmount = (earningData['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final double platformFee = (earningData['platformFee'] as num?)?.toDouble() ?? 0.0;
    final double paymentAmount = (earningData['paymentAmount'] as num?)?.toDouble() ?? 0.0;
    final String earningStatus = earningData['earningStatus'] ?? 'Unknown';
    final Timestamp? paymentAt = earningData['paymentAt'] as Timestamp?;
    final String paymentDate = paymentAt != null
        ? "${paymentAt.toDate().day} ${_getMonthName(paymentAt.toDate().month)} ${paymentAt.toDate().year} at ${_formatTime(paymentAt.toDate())}"
        : 'Unknown Date';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking ID: $bookingId',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: earningStatus == 'Completed' ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    earningStatus,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Service: $serviceName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildAmountRow('Pay by user Amount', paymentAmount),
            _buildAmountRow('Tax (11%)', taxAmount),
            _buildAmountRow('Platform Fee', platformFee),
            Divider(),
            _buildAmountRow('Recevied Amount', serviceAmount , isBold: true),
            SizedBox(height: 8),
            Text(
              'Paid on: $paymentDate',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}