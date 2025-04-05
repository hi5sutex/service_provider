import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool hasViewPermission = false;
  bool hasManagePermission = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Simulated permission check (replace with real logic)
    setState(() {
      hasViewPermission = true; // Example: Replace with actual permission
      hasManagePermission = true; // Example: Replace with actual permission
    });
  }

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    List<Map<String, dynamic>> bookings = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Collect unique IDs for users, services, and providers
    Set<String> userIds = bookings.map((b) => b['userId'] as String).toSet();
    Set<String> serviceIds = bookings.map((b) => b['serviceId'] as String).toSet();
    Set<String> providerIds = bookings.map((b) => b['providerId'] as String).toSet();

    // Fetch all related documents in parallel and create MapEntries explicitly
    Map<String, DocumentSnapshot> userDocs = Map.fromEntries(
      await Future.wait(
        userIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('users').doc(id).get(),
          ),
        ),
      ),
    );
    Map<String, DocumentSnapshot> serviceDocs = Map.fromEntries(
      await Future.wait(
        serviceIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('services').doc(id).get(),
          ),
        ),
      ),
    );
    Map<String, DocumentSnapshot> providerDocs = Map.fromEntries(
      await Future.wait(
        providerIds.map(
              (id) async => MapEntry(
            id,
            await FirebaseFirestore.instance.collection('providers').doc(id).get(),
          ),
        ),
      ),
    );

    // Attach fetched data to bookings with proper null safety
    for (var booking in bookings) {
      final userDoc = userDocs[booking['userId']];
      final serviceDoc = serviceDocs[booking['serviceId']];
      final providerDoc = providerDocs[booking['providerId']];

      booking['userName'] = userDoc != null && userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
      booking['serviceName'] = serviceDoc != null && serviceDoc.exists
          ? (serviceDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
      booking['providerName'] = providerDoc != null && providerDoc.exists
          ? (providerDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
          : 'Unknown';
    }

    return bookings;
  }

  // Filter bookings based on selected filter and search query
  List<Map<String, dynamic>> _filterBookings(List<Map<String, dynamic>> bookings) {
    return bookings.where((booking) {
      // Apply status filter if not "All"
      bool matchesFilter = _selectedFilter == 'All' ||
          booking['status']?.toLowerCase() == _selectedFilter.toLowerCase();

      // Apply search filter if search query is not empty
      bool matchesSearch = _searchQuery.isEmpty ||
          booking['userName']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          booking['serviceName']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          booking['providerName']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          booking['id']?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'completed':
        return Color(0xFF060644);
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        backgroundColor: Color(0xFF060644),
        elevation: 0,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: () {
          //     setState(() {}); // Refresh the data
          //   },
          // ),
        ],
      ),
      body: hasViewPermission
          ? Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerEffect();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading bookings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF060644),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final bookings = _filterBookings(snapshot.data!);
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings match your filters',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your search or filter criteria',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return _buildBookingsList(bookings);
              },
            ),
          ),
          _buildBookingSummary(),
        ],
      )
          : _buildNoPermissionView(),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, service or ID...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Pending'),
                _buildFilterChip('Confirmed'),
                _buildFilterChip('Completed'),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.indigo.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: Color(0xFF060644),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? 'Unknown';
    Color statusColor = _getStatusColor(status);

    // Format date if it exists
    String formattedDate = 'N/A';
    if (booking['bookingDate'] != null) {
      try {
        // Handle different date formats
        if (booking['bookingDate'] is Timestamp) {
          formattedDate = DateFormat('MMM dd, yyyy - hh:mm a')
              .format((booking['bookingDate'] as Timestamp).toDate());
        } else if (booking['bookingDate'] is String) {
          // Assuming string format is simple, adjust as needed
          formattedDate = booking['bookingDate'];
        }
      } catch (e) {
        formattedDate = booking['bookingDate'].toString();
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: hasManagePermission
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(bookingData: booking),
            ),
          ).then((_) => setState(() {}));  // Refresh on return
        }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left section - User icon or avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.indigo.shade300,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle section - Booking details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['userName'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking['serviceName'] ?? 'Unknown Service',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Provider: ${booking['providerName'] ?? 'N/A'}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right section - Status and actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${booking['id'].toString().substring(0, min(8, booking['id'].toString().length))}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Actions row
              if (hasManagePermission)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        Icons.phone_outlined,
                        'Call',
                        Colors.blue.shade700,
                            () {/* Implement call action */},
                      ),
                      _buildActionButton(
                        Icons.chat_outlined,
                        'Message',
                        Colors.green.shade700,
                            () {/* Implement message action */},
                      ),
                      _buildActionButton(
                        Icons.edit_outlined,
                        'Edit',
                        Colors.orange.shade700,
                            () {/* Implement edit action */},
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          backgroundColor: color.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6, // Display 6 shimmer placeholders
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),

              // Content placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 150, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 200, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 180, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 12, width: 140, color: Colors.white),
                  ],
                ),
              ),

              // Status placeholder
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 24,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 50, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no bookings available in the system.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF060644),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You do not have permission to view bookings. Please contact an administrator for access.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Pending', '12', Colors.orange),
              _buildSummaryItem('Confirmed', '24', Colors.green),
              _buildSummaryItem('Completed', '103', Colors.blue),
              _buildSummaryItem('Cancelled', '5', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

extension on Color {
  get shade800 => null;
}

// Helper function to find the minimum of two integers
int min(int a, int b) {
  return a < b ? a : b;
}