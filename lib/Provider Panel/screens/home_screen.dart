import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Provider%20Panel/EarningsPage.dart';
import 'package:service_provider/Provider%20Panel/screens/manage_services.dart';
import 'package:service_provider/Provider%20Panel/screens/notification.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'add_service_screen.dart';

class ProviderHome extends StatefulWidget {
  @override
  _ProviderHomeState createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  int totalBookings = 0;
  double totalEarnings = 0.0;
  String providerName = "Provider";
  String? providerProfileImage;
  int completedBookings = 0;
  int pendingBookings = 0;
  double rating = 0.0;
  bool isLoading = true;
  bool isInitialLoad = true; // Track first load

  List<Map<String, dynamic>> recentCompletedOrCanceledBookings = [];
  List<Map<String, dynamic>> upcomingConfirmedBookings = [];

  // Cache for user addresses to avoid repeated Firestore calls
  final Map<String, String> _userAddressCache = {};

  @override
  void initState() {
    super.initState();
    // Show cached data immediately and fetch fresh data in background
    fetchProviderData();
  }

  Future<void> fetchProviderData() async {
    if (!isInitialLoad) setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final String providerId = user.uid;

    try {
      // Fetch provider details (critical data) first
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          providerName = userData['name'] ?? 'Provider';
          providerProfileImage = userData['profileImage'] as String?;
          rating = (userData['rating'] as num?)?.toDouble() ?? 4.8;
          isLoading = false; // Show UI with provider data immediately
          isInitialLoad = false;
        });
      }

      // Only fetch necessary booking data with pagination and limits
      await _fetchBookingsData(providerId);
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchBookingsData(String providerId) async {
    // OPTIMIZATION 1: Split queries and use limits to reduce data transfer
    final now = DateTime.now();

    // OPTIMIZATION 2: Use compound queries with limits for better performance

    // 1. Get completed bookings count with a lightweight count query
    final completedQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'Completed')
        .count()
        .get();

    // 2. Get pending bookings count with a lightweight count query
    final pendingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: ['Pending'])
        .count()
        .get();

    // 3. Get recent completed or canceled bookings (limited to 5)
    final completedOrCanceledQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: ['Completed', 'Cancelled'])
        .orderBy('__name__', descending: true)
        .limit(5)
        .get();

    // 4. Get upcoming confirmed bookings (limited to 3)
    final confirmedQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'Confirmed')
        .where('serviceDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('serviceDate')
        .limit(3)
        .get();

    // 5. Get total bookings count (light query)
    final totalBookingsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .count()
        .get();

    // Process completed or canceled bookings
    List<Map<String, dynamic>> completedOrCanceled = [];
    List<Future> addressFutures = [];

    for (var doc in completedOrCanceledQuery.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;

      final bookingData = {
        'id': doc.id,
        'customerName': data['customerName'] ?? 'Customer',
        'serviceName': data['serviceName'] ?? 'Service',
        'serviceDate': (data['serviceDate'] as Timestamp?)?.toDate() ?? now,
        'amount': (data['paymentAmount'] as num?)?.toDouble() ?? 0.0,
        'status': data['status'] ?? '',
        'location': 'Loading...',
        'userId': userId
      };

      completedOrCanceled.add(bookingData);

      // Add to futures list to resolve later
      if (userId != null) {
        addressFutures.add(_getUserAddress(userId, bookingData));
      }
    }

    // Process upcoming confirmed bookings
    List<Map<String, dynamic>> confirmed = [];

    for (var doc in confirmedQuery.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;

      final bookingData = {
        'id': doc.id,
        'customerName': data['customerName'] ?? 'Customer',
        'serviceName': data['serviceName'] ?? 'Service',
        'serviceDate': (data['serviceDate'] as Timestamp?)?.toDate() ?? now,
        'amount': (data['paymentAmount'] as num?)?.toDouble() ?? 0.0,
        'status': data['status'] ?? '',
        'location': 'Loading...',
        'userId': userId
      };

      confirmed.add(bookingData);

      // Add to futures list to resolve later
      if (userId != null) {
        addressFutures.add(_getUserAddress(userId, bookingData));
      }
    }

    // OPTIMIZATION 3: Fetch all addresses in parallel
    await Future.wait(addressFutures);

    // Update state once with all the data
    setState(() {
      completedBookings = completedQuery.count!;
      pendingBookings = pendingQuery.count!;
      totalBookings = totalBookingsQuery.count!;
      recentCompletedOrCanceledBookings = completedOrCanceled;
      upcomingConfirmedBookings = confirmed;
    });
  }

  // OPTIMIZATION 4: Use caching for user addresses
  Future<void> _getUserAddress(String userId, Map<String, dynamic> bookingData) async {
    if (_userAddressCache.containsKey(userId)) {
      // Use cached address
      bookingData['location'] = _userAddressCache[userId] ?? 'Unknown Location';
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final address = (userDoc.data() as Map<String, dynamic>)['address']?['string'] ?? 'Unknown Location';
        // Cache the address
        _userAddressCache[userId] = address;
        // Update booking data
        bookingData['location'] = address;
      } else {
        bookingData['location'] = 'Unknown Location';
      }
    } catch (e) {
      print('Error fetching address: $e');
      bookingData['location'] = 'Unknown Location';
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String providerId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient, // Apply the gradient
          ),
        ),
        elevation: 4, // Keep the elevation
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: providerProfileImage != null ? NetworkImage(providerProfileImage!) : null,
              backgroundColor: ProviderTheme.accentColor,
              child: providerProfileImage == null
                  ? Text(
                providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: ProviderTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              )
                  : null,
            ),
            SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${providerName.split(' ').length > 1 ? "Provider" : providerName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ProviderTheme.onPrimaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ProviderTheme.onPrimaryTextColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, size: 28),
            color: ProviderTheme.accentColor,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchProviderData,
        color: ProviderTheme.accentColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoading ? _buildPerformanceShimmer() : _buildPerformanceCard(providerId),
              SizedBox(height: 20),
              isLoading
                  ? _buildStatusShimmer()
                  : Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Pending',
                      count: pendingBookings,
                      icon: Icons.pending_actions,
                      color: ProviderTheme.pendingColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Completed',
                      count: completedBookings,
                      icon: Icons.check_circle_outline,
                      color: ProviderTheme.completedColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              SizedBox(height: 16),
              isLoading ? _buildQuickActionsShimmer() : _buildQuickActions(),
              SizedBox(height: 24),
              _buildSectionTitle('Upcoming Bookings'),
              SizedBox(height: 16),
              isLoading
                  ? _buildBookingsShimmer(3)
                  : upcomingConfirmedBookings.isEmpty
                  ? _buildEmptyState('No upcoming confirmed bookings')
                  : Column(
                children: upcomingConfirmedBookings.map((booking) => _buildBookingCard(booking)).toList(),
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Recent Bookings'),
              SizedBox(height: 16),
              isLoading
                  ? _buildBookingsShimmer(5)
                  : recentCompletedOrCanceledBookings.isEmpty
                  ? _buildEmptyState('No recent completed or canceled bookings')
                  : Column(
                children:
                recentCompletedOrCanceledBookings.map((booking) => _buildBookingCard(booking)).toList(),
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Tips & Resources'),
              SizedBox(height: 16),
              isLoading
                  ? _buildTipsShimmer()
                  : Column(
                children: [
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
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddServiceScreen()));
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Shimmer Effects
  Widget _buildPerformanceShimmer() {
    return Shimmer.fromColors(
      baseColor: ProviderTheme.dividerColor,
      highlightColor: ProviderTheme.cardHighlightColor,
      child: Container(
        width: double.infinity,
        height: 140,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(width: 40, height: 40, color: Colors.white),
                SizedBox(height: 10),
                Container(width: 80, height: 20, color: Colors.white),
              ],
            ),
            Column(
              children: [
                Container(width: 40, height: 40, color: Colors.white),
                SizedBox(height: 10),
                Container(width: 80, height: 20, color: Colors.white),
              ],
            ),
            Column(
              children: [
                Container(width: 40, height: 40, color: Colors.white),
                SizedBox(height: 10),
                Container(width: 80, height: 20, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusShimmer() {
    return Row(
      children: [
        Expanded(child: _buildStatusCardShimmer()),
        SizedBox(width: 16),
        Expanded(child: _buildStatusCardShimmer()),
      ],
    );
  }

  Widget _buildStatusCardShimmer() {
    return Shimmer.fromColors(
      baseColor: ProviderTheme.dividerColor,
      highlightColor: ProviderTheme.cardHighlightColor,
      child: Container(
        height: 80,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(width: 40, height: 40, color: Colors.white),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 14, color: Colors.white),
                SizedBox(height: 8),
                Container(width: 40, height: 20, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionShimmer(),
            _buildQuickActionShimmer(),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionShimmer(),
            _buildQuickActionShimmer(),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Add Service',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddServiceScreen())),
            ),
            _buildQuickActionButton(
              icon: Icons.edit_note,
              label: 'Manage',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageServices())),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionButton(
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('In progress, coming soon by Abhi Patel')),
                );
              },
            ),
            _buildQuickActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Earnings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EarningsPage())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionShimmer() {
    return Shimmer.fromColors(
      baseColor: ProviderTheme.dividerColor,
      highlightColor: ProviderTheme.cardHighlightColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.44,
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Container(width: 40, height: 40, color: Colors.white),
            SizedBox(height: 10),
            Container(width: 80, height: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.44,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ProviderTheme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: ProviderTheme.shadowColor, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProviderTheme.accentColor.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: ProviderTheme.primaryColor.withOpacity(0.75)),
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: ProviderTheme.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsShimmer(int count) {
    return Column(
      children: List.generate(
        count,
            (_) => Shimmer.fromColors(
          baseColor: ProviderTheme.dividerColor,
          highlightColor: ProviderTheme.cardHighlightColor,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            height: 120,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 20, color: Colors.white),
                SizedBox(height: 8),
                Container(width: 80, height: 14, color: Colors.white),
                SizedBox(height: 8),
                Container(width: 100, height: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsShimmer() {
    return Column(
      children: List.generate(
        2,
            (_) => Shimmer.fromColors(
          baseColor: ProviderTheme.dividerColor,
          highlightColor: ProviderTheme.cardHighlightColor,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(width: 40, height: 40, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 20, color: Colors.white),
                      SizedBox(height: 8),
                      Container(width: 150, height: 14, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Actual Widgets
  Widget _buildPerformanceCard(String providerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .doc(providerId)
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        double totalEarnings = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            totalEarnings += (doc.data() as Map<String, dynamic>)['serviceAmount']?.toDouble() ?? 0.0;
          }
        }

        // Format earnings based on the value
        String formattedEarnings;
        if (totalEarnings >= 100000) {
          // Convert to Lakhs (L)
          formattedEarnings = '₹${(totalEarnings / 100000).toStringAsFixed(1)}L';
        } else {
          // Convert to Thousands (K)
          formattedEarnings = '₹${(totalEarnings / 1000).toStringAsFixed(1)}K';
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: ProviderTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: ProviderTheme.accentColor.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Performance',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ProviderTheme.onPrimaryTextColor.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space items evenly
                children: [
                  _buildStatItem(
                    label: 'Earnings',
                    value: formattedEarnings, // Use formatted earnings
                    icon: Icons.attach_money,
                  ),
                  _buildStatItem(
                    label: 'Rating',
                    value: rating.toStringAsFixed(1),
                    icon: Icons.star,
                  ),
                  _buildStatItem(
                    label: 'Bookings',
                    value: totalBookings.toString(),
                    icon: Icons.calendar_today,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({required String label, required String value, required IconData icon}) {
    return Flexible(
      fit: FlexFit.tight, // Ensure each item takes equal space
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: ProviderTheme.accentColor,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: ProviderTheme.onPrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, // Center the text
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: ProviderTheme.onPrimaryTextColor.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, // Center the text
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required String title, required int count, required IconData icon, required Color color}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: ProviderTheme.shadowColor, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (title.contains('Bookings'))
          TextButton(
            onPressed: () {},
            child: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: ProviderTheme.secondaryTextColor,
            ),
          ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final Color statusColor = getStatusColor(booking['status']);
    final DateFormat formatter = DateFormat('MMM d, yyyy • hh:mm a');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ProviderTheme.surfaceColor, ProviderTheme.cardHighlightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: ProviderTheme.shadowColor, blurRadius: 6, offset: Offset(0, 3)),
        ],
        border: Border.all(color: ProviderTheme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  booking['serviceName'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ProviderTheme.primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
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
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: ProviderTheme.secondaryTextColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking['location'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ProviderTheme.secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: ProviderTheme.secondaryTextColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  formatter.format(booking['serviceDate']),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ProviderTheme.secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '₹${booking['amount'].toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: ProviderTheme.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return ProviderTheme.completedColor;
      case 'pending':
        return ProviderTheme.pendingColor;
      case 'confirmed':
        return ProviderTheme.confirmedColor;
      case 'cancelled':
        return ProviderTheme.canceledColor;
      default:
        return ProviderTheme.secondaryTextColor;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProviderTheme.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: ProviderTheme.disabledTextColor),
          SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTipCard({required String title, required String description, required IconData icon}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        // border: Border.all(color: ProviderTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: ProviderTheme.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProviderTheme.accentColor.withOpacity(0.20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ProviderTheme.primaryColor.withOpacity(0.75), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}