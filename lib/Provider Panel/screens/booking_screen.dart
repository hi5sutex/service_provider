import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking> {
  String activeTab = 'pending';
  String? providerId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserUid();
  }

  Future<void> _fetchCurrentUserUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        providerId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: providerId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildTabBar(),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: _buildBookingList()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildTabButton('Pending', 'pending'),
          _buildTabButton('Ongoing', 'confirmed'),
          _buildTabButton('Completed', 'completed'),
          _buildTabButton('Cancelled', 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = tab;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activeTab == tab ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: activeTab == tab ? Colors.blue : Colors.grey.shade600,
              fontWeight: activeTab == tab ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: providerId)
          .where('status', isEqualTo: activeTab[0].toUpperCase() + activeTab.substring(1).toLowerCase())
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading bookings'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(booking);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(QueryDocumentSnapshot booking) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingHeader(booking),
            const SizedBox(height: 16),
            _buildBookingDetails(booking),
            const SizedBox(height: 16),
            _buildBookingActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHeader(QueryDocumentSnapshot booking) {
    final statusColor = _getStatusColor(booking['status']);
    final profileUrl = '';
    // booking['userId'] != null ? getUserProfileImageUrl(booking['userId']) as String : '';
    final userName = booking['userId'] != null ? getUserName(booking['userId']) : 'Unknown';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(profileUrl.isNotEmpty ? profileUrl : 'https://via.placeholder.com/150'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(booking['location']['local'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            booking['status'],
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetails(QueryDocumentSnapshot booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${booking['category']} - ${booking['serviceName']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(booking['bookingDate'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Payment: ', style: TextStyle(color: Colors.grey.shade600)),
            Text('₹${(booking['paymentAmount'] as int).toDouble().toStringAsFixed(2)} (${booking['paymentMode']})', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingActions(QueryDocumentSnapshot booking) {
    final actions = _getActionsForStatus(booking['status'], booking.id);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Widget> _getActionsForStatus(String status, String bookingId) {
    switch (status.toLowerCase()) {
      case 'pending':
        return [
          TextButton(onPressed: () => _updateBookingStatus(bookingId, 'declined'), child: const Text('Decline', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => _updateBookingStatus(bookingId, 'approved'), child: const Text('Approve')),
        ];
      case 'ongoing':
        return [
          ElevatedButton(onPressed: () => _updateBookingStatus(bookingId, 'completed'), child: const Text('Complete Service')),
        ];
      default:
        return [];
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': newStatus});
      Navigator.of(context).pop(); // Dismiss the dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus.')));
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss the dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  String getFormattedActiveTab(String activeTab) {
    return activeTab[0].toUpperCase() + activeTab.substring(1).toLowerCase();
  }

  Future<String?> getUserProfileImageUrl(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['profileImage'] as String? : null;
  }

  Future<String?> getUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] as String? : null;
  }
}
