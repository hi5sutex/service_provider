import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/User Panel/BookingTrackingPage.dart';

class UserBooking extends StatefulWidget {
  @override
  _UserBookingState createState() => _UserBookingState();
}

class _UserBookingState extends State<UserBooking> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _selectedStatus = 'All'; // Default sorting option

  // Filter options with icons (similar to NotificationPage, added "Completed")
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'Pending', 'icon': Icons.pending},
    {'label': 'Confirmed', 'icon': Icons.check_circle_outline},
    {'label': 'Ongoing', 'icon': Icons.hourglass_top},
    {'label': 'Completed', 'icon': Icons.check_circle}, // New "Completed" option
    {'label': 'Cancelled', 'icon': Icons.cancel},
  ];

  // Store all necessary data locally
  Map<String, String> _serviceNames = {};
  Map<String, Map<String, dynamic>> _providerDetails = {};
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Get all services
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .get();

      for (var doc in servicesSnapshot.docs) {
        String name = doc.data()['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          _serviceNames[doc.id] = name;
        }
      }

      // Get user's bookings
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser?.uid)
          .get();

      // Extract provider IDs
      Set<String> providerIds = {};
      for (var doc in bookingsSnapshot.docs) {
        var data = doc.data();
        String? providerId = data['providerId'] as String?;
        if (providerId != null) {
          providerIds.add(providerId);
        }
      }

      // Fetch all providers in a single batch
      if (providerIds.isNotEmpty) {
        final providerQueries = providerIds.map((id) =>
            FirebaseFirestore.instance.collection('providers').doc(id).get()
        ).toList();

        final providerSnapshots = await Future.wait(providerQueries);

        for (var snapshot in providerSnapshots) {
          if (snapshot.exists) {
            _providerDetails[snapshot.id] = {
              'name': snapshot.data()?['name'] ?? 'Unknown Provider',
              'profileImage': snapshot.data()?['profileImage'] ?? 'https://via.placeholder.com/50'
            };
          }
        }
      }

      // Process all bookings and sort by bookingDate (descending)
      for (var doc in bookingsSnapshot.docs) {
        var data = doc.data();
        String serviceId = data['serviceId'] ?? '';
        String providerId = data['providerId'] ?? '';

        // Format dates and times
        String formattedServiceDate = data['serviceDate'] != null
            ? formatDate(data['serviceDate'] as Timestamp)
            : 'Not specified';

        String formattedBookingDate = data['bookingDate'] != null
            ? formatDate(data['bookingDate'] as Timestamp)
            : 'Not specified';

        String serviceTime = data['serviceDate'] != null
            ? formatTime(data['serviceDate'] as Timestamp)
            : 'Not specified';

        // Get service name with proper capitalization
        String serviceName = 'Unknown Service';
        if (_serviceNames.containsKey(serviceId)) {
          serviceName = _serviceNames[serviceId]!;
          // Capitalize first letter of each word
          serviceName = serviceName.split(' ').map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
          ).join(' ');
        }

        // Get provider details
        String providerName = _providerDetails[providerId]?['name'] ?? 'Unknown Provider';
        String providerImage = _providerDetails[providerId]?['profileImage'] ?? 'https://via.placeholder.com/50';

        // Create complete booking record
        _bookings.add({
          'id': doc.id,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'serviceNameLower': serviceName.toLowerCase(), // For case-insensitive search
          'serviceDate': formattedServiceDate,
          'serviceTime': serviceTime,
          'bookingDate': formattedBookingDate,
          'bookingTimestamp': data['bookingDate'] as Timestamp?, // For sorting
          'providerId': providerId,
          'providerName': providerName,
          'providerImage': providerImage,
          'location': data['location'] != null && data['location'] is Map
              ? data['location']['local'] ?? 'Unknown Location'
              : 'Unknown Location',
          'price': '\$${data['paymentAmount'] ?? '0'}',
          'status': data['status'] ?? 'Pending', // Store status for filtering
          'rawData': data, // Keep original data
        });
      }

      // Sort bookings by bookingTimestamp (descending)
      _bookings.sort((a, b) {
        if (a['bookingTimestamp'] == null || b['bookingTimestamp'] == null) return 0;
        return b['bookingTimestamp'].compareTo(a['bookingTimestamp']);
      });

      _filteredBookings = List.from(_bookings);

    } catch (e) {
      print("Error loading data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      _performLocalSearchAndSort();
    });
  }

  void _performLocalSearchAndSort() {
    List<Map<String, dynamic>> tempBookings = List.from(_bookings);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      tempBookings = tempBookings.where((booking) {
        return booking['serviceNameLower'].contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'All') {
      tempBookings = tempBookings.where((booking) {
        return booking['status'] == _selectedStatus;
      }).toList();
    }

    // Sort by bookingTimestamp (descending)
    tempBookings.sort((a, b) {
      if (a['bookingTimestamp'] == null || b['bookingTimestamp'] == null) return 0;
      return b['bookingTimestamp'].compareTo(a['bookingTimestamp']);
    });

    setState(() {
      _filteredBookings = tempBookings;
    });
  }

  void _onStatusChanged(String? newValue) {
    setState(() {
      _selectedStatus = newValue ?? 'All';
      _performLocalSearchAndSort(); // Trigger sorting and filtering immediately
    });
  }

  String formatDate(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  String formatTime(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060644), // Primary color as background
      appBar: AppBar(
        backgroundColor: Color(0xFF060644),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by service name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.white),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          // Sorting filter (similar to NotificationPage, with "Completed" added)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filterOptions.map((filter) {
                bool isSelected = _selectedStatus == filter['label'];
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      _onStatusChanged(filter['label']); // Trigger sorting on click
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.white : Color(0xFF060644),
                      foregroundColor: isSelected ? Color(0xFF060644) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'],
                          size: 18,
                          color: isSelected ? Color(0xFF060644) : Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          filter['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Booking list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Secondary color for the content area
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _isLoading
                  ? ListView.builder(
                itemCount: 3,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                itemBuilder: (context, index) => ShimmerBookingCard(),
              )
                  : _bookings.isEmpty
                  ? _buildEmptyState('No Bookings Yet')
                  : _filteredBookings.isEmpty
                  ? _buildEmptyState('No matching bookings found',
                  subtitle: 'Try a different search term or status')
                  : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                itemCount: _filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = _filteredBookings[index];
                  return BookingCard(
                    serviceName: booking['serviceName'],
                    serviceDate: booking['serviceDate'],
                    serviceTime: booking['serviceTime'],
                    bookingDate: booking['bookingDate'],
                    providerName: booking['providerName'],
                    providerImage: booking['providerImage'],
                    location: booking['location'],
                    price: booking['price'],
                    status: booking['status'],
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingTrackingPage(
                            bookingId: booking['id'],
                            bookingData: booking['rawData'],
                            serviceName: booking['serviceName'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16), // Ensure padding at the bottom
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ]
        ],
      ),
    );
  }
}

class ShimmerBookingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 150,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 180,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: 200,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 6),
              Container(
                width: 80,
                height: 14,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String serviceName;
  final String serviceDate;
  final String serviceTime;
  final String bookingDate;
  final String providerName;
  final String providerImage;
  final String location;
  final String price;
  final String status;
  final VoidCallback onViewDetails;

  BookingCard({
    required this.serviceName,
    required this.serviceDate,
    required this.serviceTime,
    required this.bookingDate,
    required this.providerName,
    required this.providerImage,
    required this.location,
    required this.price,
    required this.status,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white, // Secondary color for cards
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serviceName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF060644)),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Service Date: $serviceDate',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Time: $serviceTime',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.event_note, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Booking Date: $bookingDate',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(providerImage),
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    Text(
                      'Service Provider',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Price: $price',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF060644)),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF060644), // Primary color for text
                  ),
                  child: Text('View Details', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF060644), // Primary color for text
                  ),
                  child: Text('Reschedule', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red, // Keep red for cancel
                  ),
                  child: Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}