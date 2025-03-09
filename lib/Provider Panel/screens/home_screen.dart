import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Provider%20Panel/EarningsPage.dart';
import 'package:service_provider/Provider%20Panel/screens/manage_services.dart';
import 'package:service_provider/Provider%20Panel/screens/notification.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'add_service_screen.dart';

class ProviderHome extends StatefulWidget {
  @override
  _ProviderHomeState createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  final Color primaryColor = Color(0xFF060644);
  final Color secondaryColor = Colors.white;
  final Color accentColor = Color(0xFF4A4AFF);

  int totalBookings = 0;
  double totalEarnings = 0.0;
  String providerName = "Provider";
  int completedBookings = 0;
  int pendingBookings = 0;
  double rating = 0.0;
  bool isLoading = true;

  List<Map<String, dynamic>> recentBookings = [];

  @override
  void initState() {
    super.initState();
    fetchProviderData();
  }

  Future<void> fetchProviderData() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final String providerId = user.uid;

    try {
      // Fetch provider information
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          providerName = userData['name'] ?? 'Provider';
          rating = (userData['rating'] as num?)?.toDouble() ?? 4.8;
        });
      }

      // Fetch booking information - This is the part that matters for total bookings
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: providerId)
          .get();  // Make sure we get ALL bookings, not just recent ones

      int completed = 0;
      int pending = 0;
      List<Map<String, dynamic>> recent = [];

      // Process the bookings
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';

        if (status.toLowerCase() == 'completed') {
          completed++;
        } else if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'scheduled') {
          pending++;
        }

        // Only add the most recent 5 bookings to the recent list
        if (recent.length < 5) {
          recent.add({
            'id': doc.id,
            'customerName': data['customerName'] ?? 'Customer',
            'serviceName': data['serviceName'] ?? 'Service',
            'bookingDate': data['bookingDate'] != null
                ? (data['bookingDate'] as Timestamp).toDate()
                : DateTime.now(),
            'amount': (data['paymentAmount'] as num?)?.toDouble() ?? 0.0,
            'status': status,
          });
        }
      }

      // Update the state with all the fetched data
      setState(() {
        totalBookings = bookingsSnapshot.docs.length;  // This is the important line for your issue
        completedBookings = completed;
        pendingBookings = pending;
        recentBookings = recent;
        isLoading = false;
      });

      print('Total bookings found: ${bookingsSnapshot.docs.length}');  // Debug log
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String providerId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor,
              child: Text(
                providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $providerName',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Provider Dashboard',
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: primaryColor, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                },
              ),

            ],
          ),

        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchProviderData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('earnings')
                    .doc(providerId)
                    .collection('records')
                    .snapshots(),
                builder: (context, snapshot) {
                  double totalEarnings = 0.0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = (data['serviceAmount'] as num?)?.toDouble() ?? 0.0;
                      totalEarnings += amount;
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Color(0xFF1A1A7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Performance',
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: _buildStatItem(
                                label: 'Total Earnings',
                                value: '\₹ ${totalEarnings.toStringAsFixed(2)}',
                                icon: Icons.attach_money,
                                color: secondaryColor,
                              ),
                            ),
                            Container(height: 40, width: 1, color: secondaryColor.withOpacity(0.3)),
                            Flexible(
                              child: _buildStatItem(
                                label: 'Rating',
                                value: rating.toStringAsFixed(1),
                                icon: Icons.star,
                                color: secondaryColor,
                              ),
                            ),
                            Container(height: 40, width: 1, color: secondaryColor.withOpacity(0.3)),
                            Flexible(
                              child: _buildStatItem(
                                label: 'Total Bookings',
                                value: totalBookings.toString(),
                                icon: Icons.calendar_today,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Pending',
                      count: pendingBookings,
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Completed',
                      count: completedBookings,
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Add Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddServiceScreen()),
                    ),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.edit_note,
                    label: 'Manage Services',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageServices()),
                    ),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'In progress, coming soon by Abhi Patel',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: primaryColor, // Use your primary color
                          duration: Duration(seconds: 3), // How long the notification stays
                          behavior: SnackBarBehavior.floating, // Makes it float above the UI
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Earnings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EarningsPage()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Recent Bookings'),
              SizedBox(height: 16),
              recentBookings.isEmpty
                  ? _buildEmptyState('No recent bookings found')
                  : Column(
                children: recentBookings.map((booking) => _buildBookingItem(booking)).toList(),
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Tips & Resources'),
              SizedBox(height: 16),
              _buildTipCard(
                title: 'Improve Your Profile',
                description: 'Complete your profile and add high-quality photos to attract more customers.',
                icon: Icons.person_outline,
              ),
              SizedBox(height: 12),
              _buildTipCard(
                title: 'Respond Quickly',
                description: 'Fast responses lead to 50% more bookings. Try to respond within an hour.',
                icon: Icons.speed,
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: secondaryColor),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddServiceScreen()),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the helper widgets remain the same
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        if (title == 'Recent Bookings')
          TextButton(
            onPressed: () {},
            child: Text(
              'View All',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    final Color statusColor = getStatusColor(booking['status']);
    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(
              booking['customerName'].isNotEmpty
                  ? booking['customerName'][0].toUpperCase()
                  : 'C',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['serviceName'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      booking['customerName'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      formatter.format(booking['bookingDate']),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\₹ ${booking['amount'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}