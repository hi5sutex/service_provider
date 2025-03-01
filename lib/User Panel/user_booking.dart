import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class UserBooking extends StatefulWidget {
  @override
  _UserBookingState createState() => _UserBookingState();
}

class _UserBookingState extends State<UserBooking> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  // Store all necessary data locally to avoid multiple Firebase calls
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

  // Load all necessary data once at the beginning
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Get all services first
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

      // Extract provider IDs from bookings to fetch them in a single batch
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

      // Process all bookings and prepare the complete data
      for (var doc in bookingsSnapshot.docs) {
        var data = doc.data();
        String serviceId = data['serviceId'] ?? '';
        String providerId = data['providerId'] ?? '';

        // Format dates
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
        String providerName = 'Unknown Provider';
        String providerImage = 'https://via.placeholder.com/50';
        if (_providerDetails.containsKey(providerId)) {
          providerName = _providerDetails[providerId]!['name'] ?? providerName;
          providerImage = _providerDetails[providerId]!['profileImage'] ?? providerImage;
        }

        // Create complete booking record
        _bookings.add({
          'id': doc.id,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'serviceNameLower': serviceName.toLowerCase(), // For case-insensitive search
          'serviceDate': formattedServiceDate,
          'serviceTime': serviceTime,
          'bookingDate': formattedBookingDate,
          'providerId': providerId,
          'providerName': providerName,
          'providerImage': providerImage,
          'location': data['location'] != null && data['location'] is Map
              ? data['location']['local'] ?? 'Unknown Location'
              : 'Unknown Location',
          'price': '\$${data['paymentAmount'] ?? '0'}',
          'rawData': data, // Keep original data for reference if needed
        });
      }

      // Initialize filtered bookings with all bookings
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
      _performLocalSearch();
    });
  }

  void _performLocalSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredBookings = List.from(_bookings);
      });
      return;
    }

    setState(() {
      _filteredBookings = _bookings.where((booking) {
        return booking['serviceNameLower'].contains(_searchQuery);
      }).toList();
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by service name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? ListView.builder(
                itemCount: 3, // Show 3 shimmer cards while loading
                itemBuilder: (context, index) => ShimmerBookingCard(),
              )
                  : _bookings.isEmpty
                  ? _buildEmptyState('No Bookings Yet')
                  : _filteredBookings.isEmpty
                  ? _buildEmptyState('No matching bookings found',
                  subtitle: 'Try a different search term')
                  : ListView.builder(
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
                  );
                },
              ),
            ),

            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
                backgroundColor: Color(0xFF060644),
              ),
              child: Text('Book New Service', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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

// Keep the ShimmerBookingCard and BookingCard classes as they were
class ShimmerBookingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
                width: 200,
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

  BookingCard({
    required this.serviceName,
    required this.serviceDate,
    required this.serviceTime,
    required this.bookingDate,
    required this.providerName,
    required this.providerImage,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Service Date: $serviceDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Time: $serviceTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.event_note, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Booking Date: $bookingDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(providerImage),
                  radius: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(providerName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                    Text('Service Provider',
                        style: TextStyle(fontSize: 12, color: Colors.grey)
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Price: $price',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF060644)),
            ),
            SizedBox(height: 12),
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