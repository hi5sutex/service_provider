import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchUserBookings() async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> bookings = bookingsSnapshot.docs.map((doc) {
      Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;
      booking['id'] = doc.id;
      return booking;
    }).toList();

    await Future.wait(bookings.map((booking) async {
      if (booking['serviceId'] != null) {
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(booking['serviceId'])
            .get();
        if (serviceDoc.exists) {
          booking['serviceName'] = (serviceDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Service';
        }
      }
      if (booking['bookingDate'] is Timestamp) {
        booking['bookingDate'] = DateFormat('dd/MM/yyyy kk:mm').format((booking['bookingDate'] as Timestamp).toDate());
      }
    }));

    return bookings;
  }

  Future<List<Map<String, dynamic>>> _fetchUserPayments() async {
    QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();
    return paymentsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  bool _isAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin())
            IconButton(
              icon: const Icon(Icons.block),
              tooltip: 'Block User',
              onPressed: () => _showBlockConfirmationDialog(context),
            ),
          if (_isAdmin())
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete User',
              onPressed: () => _showDeleteConfirmationDialog(context),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildUserShimmer();
          }
          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading user details.',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final user = userSnapshot.data!;
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildUserHeader(user, context, theme, screenSize),
                TabBar(
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.primaryColor,
                  tabs: const [
                    Tab(text: 'Bookings', icon: Icon(Icons.calendar_today)),
                    Tab(text: 'Payments', icon: Icon(Icons.payment)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBookingsTab(context, theme),
                      _buildPaymentsTab(context, theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic> user, BuildContext context, ThemeData theme, Size screenSize) {
    final isBlocked = user['isBlocked'] == true;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'user-${userId}',
                    child: Container(
                      width: screenSize.width * 0.25,
                      height: screenSize.width * 0.25,
                      constraints: const BoxConstraints(maxWidth: 120, maxHeight: 120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            user['profileImage'] ?? 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isBlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'BLOCKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'N/A',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.email, user['email'] ?? 'N/A', Colors.white),
                    _buildInfoRow(Icons.phone, user['phone'] ?? 'N/A', Colors.white),
                    _buildInfoRow(
                      Icons.calendar_today,
                      user['createdAt'] != null
                          ? DateFormat('dd/MM/yyyy').format((user['createdAt'] as Timestamp).toDate())
                          : 'N/A',
                      Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserBookings(),
      builder: (context, bookingsSnapshot) {
        if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildBookingsShimmer();
        }
        if (bookingsSnapshot.hasError) {
          return _buildErrorWidget('Error loading bookings');
        }

        final bookings = bookingsSnapshot.data ?? [];
        if (bookings.isEmpty) {
          return _buildEmptyState('No bookings available', Icons.calendar_today);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(booking, context, theme);
          },
        );
      },
    );
  }

  Widget _buildPaymentsTab(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserPayments(),
      builder: (context, paymentsSnapshot) {
        if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildPaymentsShimmer();
        }
        if (paymentsSnapshot.hasError) {
          return _buildErrorWidget('Error loading payments');
        }

        final payments = paymentsSnapshot.data ?? [];
        if (payments.isEmpty) {
          return _buildEmptyState('No payments available', Icons.payment);
        }

        double totalAmount = 0;
        for (var payment in payments) {
          final amount = double.tryParse(payment['paymentAmount']?.toString() ?? '0') ?? 0;
          totalAmount += amount;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Spent:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return _buildPaymentCard(payment, theme);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, BuildContext context, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (booking['status']?.toString().toLowerCase() ?? '') {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingData: booking),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking['serviceName'] ?? 'N/A',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          booking['status'] ?? 'N/A',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking['bookingDate'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, ThemeData theme) {
    String formattedDate = 'N/A';
    if (payment['paymentDate'] is Timestamp) {
      formattedDate = DateFormat('dd/MM/yyyy HH:mm').format((payment['paymentDate'] as Timestamp).toDate());
    } else if (payment['paymentDate'] != null) {
      formattedDate = payment['paymentDate'].toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.attach_money,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${payment['paymentAmount'] ?? 'N/A'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  if (payment['bookingId'] != null)
                    Text(
                      'Booking ID: ${payment['bookingId']}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: const Text(
            'Are you sure you want to block this user? They will no longer be able to use the platform.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Block', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBlocked': true});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked successfully!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully!')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 80,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}