import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/User%20Panel/BookingTrackingPage.dart';
import 'package:service_provider/theme.dart';

class UserBooking extends StatefulWidget {
  const UserBooking({super.key});

  @override
  _UserBookingState createState() => _UserBookingState();
}

class _UserBookingState extends State<UserBooking> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _selectedStatus = 'All';

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'Pending', 'icon': Icons.pending},
    {'label': 'Confirmed', 'icon': Icons.check_circle_outline},
    {'label': 'Ongoing', 'icon': Icons.hourglass_top},
    {'label': 'Completed', 'icon': Icons.check_circle},
    {'label': 'Cancelled', 'icon': Icons.cancel},
  ];

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

      final servicesSnapshot =
      await FirebaseFirestore.instance.collection('services').get();

      for (var doc in servicesSnapshot.docs) {
        String name = doc.data()['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          _serviceNames[doc.id] = name;
        }
      }

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser?.uid)
          .get();

      Set<String> providerIds = {};
      for (var doc in bookingsSnapshot.docs) {
        var data = doc.data();
        String? providerId = data['providerId'] as String?;
        if (providerId != null) {
          providerIds.add(providerId);
        }
      }

      if (providerIds.isNotEmpty) {
        final providerQueries = providerIds
            .map((id) => FirebaseFirestore.instance
            .collection('providers')
            .doc(id)
            .get())
            .toList();
        final providerSnapshots = await Future.wait(providerQueries);

        for (var snapshot in providerSnapshots) {
          if (snapshot.exists) {
            _providerDetails[snapshot.id] = {
              'name': snapshot.data()?['name'] ?? 'Unknown Provider',
              'profileImage': snapshot.data()?['profileImage'] ??
                  'https://via.placeholder.com/50'
            };
          }
        }
      }

      for (var doc in bookingsSnapshot.docs) {
        var data = doc.data();
        String serviceId = data['serviceId'] ?? '';
        String providerId = data['providerId'] ?? '';

        String formattedServiceDate = data['serviceDate'] != null
            ? formatDate(data['serviceDate'] as Timestamp)
            : 'Not specified';

        String formattedBookingDate = data['bookingDate'] != null
            ? formatDate(data['bookingDate'] as Timestamp)
            : 'Not specified';

        String serviceTime = data['serviceDate'] != null
            ? formatTime(data['serviceDate'] as Timestamp)
            : 'Not specified';

        String serviceName = 'Unknown Service';
        if (_serviceNames.containsKey(serviceId)) {
          serviceName = _serviceNames[serviceId]!;
          serviceName = serviceName
              .split(' ')
              .map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
              .join(' ');
        }

        String providerName =
            _providerDetails[providerId]?['name'] ?? 'Unknown Provider';
        String providerImage = _providerDetails[providerId]?['profileImage'] ??
            'https://via.placeholder.com/50';

        _bookings.add({
          'id': doc.id,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'serviceNameLower': serviceName.toLowerCase(),
          'serviceDate': formattedServiceDate,
          'serviceTime': serviceTime,
          'bookingDate': formattedBookingDate,
          'bookingTimestamp': data['bookingDate'] as Timestamp?,
          'providerId': providerId,
          'providerName': providerName,
          'providerImage': providerImage,
          'location': data['location'] != null && data['location'] is Map
              ? data['location']['local'] ?? 'Unknown Location'
              : 'Unknown Location',
          'price': '\$${data['paymentAmount'] ?? '0'}',
          'status': data['status'] ?? 'Pending',
          'rawData': data,
        });
      }

      _bookings.sort((a, b) {
        if (a['bookingTimestamp'] == null || b['bookingTimestamp'] == null) {
          return 0;
        }
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

    if (_searchQuery.isNotEmpty) {
      tempBookings = tempBookings.where((booking) {
        return booking['serviceNameLower'].contains(_searchQuery);
      }).toList();
    }

    if (_selectedStatus != 'All') {
      tempBookings = tempBookings.where((booking) {
        return booking['status'] == _selectedStatus;
      }).toList();
    }

    tempBookings.sort((a, b) {
      if (a['bookingTimestamp'] == null || b['bookingTimestamp'] == null) {
        return 0;
      }
      return b['bookingTimestamp'].compareTo(a['bookingTimestamp']);
    });

    setState(() {
      _filteredBookings = tempBookings;
    });
  }

  void _onStatusChanged(String? newValue) {
    setState(() {
      _selectedStatus = newValue ?? 'All';
      _performLocalSearchAndSort();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.primaryColorCustom,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColorCustom,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.secondaryColorCustom, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bookings',
          style: TextStyle(
            color: AppTheme.secondaryColorCustom,
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by service name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AppTheme.secondaryColorCustom),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AppTheme.secondaryColorCustom),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AppTheme.secondaryColorCustom),
                ),
                prefixIcon:
                Icon(Icons.search, color: AppTheme.secondaryColorCustom),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: AppTheme.secondaryColorCustom),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                hintStyle: TextStyle(
                    color: AppTheme.secondaryColorCustom.withOpacity(0.7)),
                filled: true,
                fillColor: AppTheme.secondaryColorCustom.withOpacity(0.1),
              ),
              style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: AppTheme.secondaryColorCustom),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.08,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
              child: Row(
                children: _filterOptions.map((filter) {
                  bool isSelected = _selectedStatus == filter['label'];
                  return Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.02),
                    child: ElevatedButton(
                      onPressed: () {
                        _onStatusChanged(filter['label']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppTheme.secondaryColorCustom
                            : AppTheme.primaryColorCustom,
                        foregroundColor: isSelected
                            ? AppTheme.primaryColorCustom
                            : AppTheme.secondaryColorCustom,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.015),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'],
                            size: screenWidth * 0.045,
                            color: isSelected
                                ? AppTheme.primaryColorCustom
                                : AppTheme.secondaryColorCustom,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            filter['label'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
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
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColorCustom,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _isLoading
                  ? ListView.builder(
                itemCount: 3,
                padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.01,
                    horizontal: screenWidth * 0.01),
                itemBuilder: (context, index) => ShimmerBookingCard(
                    screenWidth: screenWidth, screenHeight: screenHeight),
              )
                  : _bookings.isEmpty
                  ? _buildEmptyState('No Bookings Yet')
                  : _filteredBookings.isEmpty
                  ? _buildEmptyState('No matching bookings found',
                  subtitle: 'Try a different search term or status')
                  : ListView.builder(
                padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.01,
                    horizontal: screenWidth * 0.01),
                itemCount: _filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = _filteredBookings[index];
                  return BookingCard(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
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
                          builder: (context) =>
                              BookingTrackingPage(
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
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border,
              size: MediaQuery.of(context).size.width * 0.15,
              color: AppTheme.greyLight),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            message,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          if (subtitle != null) ...[
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: AppTheme.greyLight),
            ),
          ]
        ],
      ),
    );
  }
}

class ShimmerBookingCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const ShimmerBookingCard(
      {required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.04),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppTheme.secondaryColorCustom, // Set card background to white
      child: Shimmer.fromColors(
        baseColor: AppTheme.greyLight,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.025,
                color: AppTheme.secondaryColorCustom, // Changed to white
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.035,
                    height: screenWidth * 0.035,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Container(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.035,
                    height: screenWidth * 0.035,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Container(
                    width: screenWidth * 0.25,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.035,
                    height: screenWidth * 0.035,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Container(
                    width: screenWidth * 0.5,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundColor:
                    AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.017,
                        color: AppTheme.secondaryColorCustom, // Changed to white
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Container(
                        width: screenWidth * 0.2,
                        height: screenHeight * 0.015,
                        color: AppTheme.secondaryColorCustom, // Changed to white
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.035,
                    height: screenWidth * 0.035,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Container(
                    width: screenWidth * 0.55,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.007),
              Container(
                width: screenWidth * 0.2,
                height: screenHeight * 0.017,
                color: AppTheme.secondaryColorCustom, // Changed to white
              ),
              SizedBox(height: screenHeight * 0.015),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  Container(
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
                  ),
                  Container(
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.015,
                    color: AppTheme.secondaryColorCustom, // Changed to white
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
  final double screenWidth;
  final double screenHeight;
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

  const BookingCard({
    required this.screenWidth,
    required this.screenHeight,
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
      margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.04),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppTheme.secondaryColorCustom,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serviceName,
              style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColorCustom),
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: screenWidth * 0.035, color: AppTheme.greyLight),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Service Date: $serviceDate',
                  style: TextStyle(
                      fontSize: screenWidth * 0.03, color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: screenWidth * 0.035, color: AppTheme.greyLight),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Time: $serviceTime',
                  style: TextStyle(
                      fontSize: screenWidth * 0.03, color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.event_note,
                    size: screenWidth * 0.035, color: AppTheme.greyLight),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  'Booking Date: $bookingDate',
                  style: TextStyle(
                      fontSize: screenWidth * 0.03, color: Colors.black54),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(providerImage),
                  radius: screenWidth * 0.05,
                  backgroundColor: AppTheme.greyLight,
                ),
                SizedBox(width: screenWidth * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    Text(
                      'Service Provider',
                      style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: AppTheme.greyLight),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: screenWidth * 0.035, color: AppTheme.greyLight),
                SizedBox(width: screenWidth * 0.01),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                        fontSize: screenWidth * 0.03, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Price: $price',
              style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColorCustom),
            ),
            SizedBox(height: screenHeight * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColorCustom,
                  ),
                  child: Text('View Details',
                      style: TextStyle(fontSize: screenWidth * 0.03)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColorCustom,
                  ),
                  child: Text('Reschedule',
                      style: TextStyle(fontSize: screenWidth * 0.03)),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                  ),
                  child: Text('Cancel',
                      style: TextStyle(fontSize: screenWidth * 0.03)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}