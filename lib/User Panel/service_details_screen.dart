import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/ConfirmBookingPage.dart';
import 'package:service_provider/User Panel/chat_funtionality/chat_screen.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';
import 'package:shimmer/shimmer.dart'; // Add this package to pubspec.yaml

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId})
      : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? providerData;
  late PageController _pageController;
  int _currentPage = 0;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isFavorite = false;

  // Define consistent color scheme
  final Color primaryColor = Color(0xFF0A2463); // Deep blue
  final Color accentColor = Color(0xFF3E92CC);  // Medium blue
  final Color highlightColor = Color(0xFF2DC7FF); // Light blue
  final Color textColor = Color(0xFF333333); // Near black
  final Color backgroundColor = Color(0xFFF8F9FA); // Light grey

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchServiceAndProviderDetails();
    _checkIfFavorited();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    final RegExp regex = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$');
    final match = regex.firstMatch(time);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  Future<void> _fetchServiceAndProviderDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await _firestore
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        serviceData = serviceSnapshot.data() as Map<String, dynamic>;
        String providerId = serviceData!['createdBy'];

        DocumentSnapshot providerSnapshot = await _firestore
            .collection('providers')
            .doc(providerId)
            .get();

        if (providerSnapshot.exists) {
          setState(() {
            providerData = providerSnapshot.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print('Error fetching service or provider details: $e');
    }
  }

  Future<void> _checkIfFavorited() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        List<dynamic> favServices = userData?['favser'] ?? [];
        setState(() {
          isFavorite = favServices.contains(widget.serviceId);
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentReference userDocRef = _firestore.collection('users').doc(currentUser.uid);
      DocumentSnapshot userDoc = await userDocRef.get();

      // If user document exists
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> favServices = List<dynamic>.from(userData['favser'] ?? []);

        // Toggle favorite status
        if (favServices.contains(widget.serviceId)) {
          favServices.remove(widget.serviceId);
        } else {
          favServices.add(widget.serviceId);
        }

        // Update in Firestore
        await userDocRef.update({'favser': favServices});

        // Update state
        setState(() {
          isFavorite = favServices.contains(widget.serviceId);
        });

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite
                ? 'Added to favorites!'
                : 'Removed from favorites!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Create user document if it doesn't exist
        await userDocRef.set({
          'favser': [widget.serviceId],
        });
        setState(() {
          isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to add favorites.')),
      );
    }
  }

  void _navigateToChat(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null && providerData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: currentUser.uid,
            receiverId: serviceData!['createdBy'],
            senderEmail: currentUser.email!,
            receiverEmail: providerData!['email'],
            receiverName: providerData!['name'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to send messages.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.7),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(
                icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : primaryColor
                ),
                onPressed: _toggleFavorite,
              ),
            ),
          ),
        ],
      ),
      body: serviceData == null
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(size),
            Transform.translate(
              offset: Offset(0, -30),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10), // Reduced bottom padding from 20 to 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceHeaderSection(),
                      SizedBox(height: 24),
                      _buildDescriptionSection(),
                      SizedBox(height: 24),
                      _buildIncludedSection(),
                      SizedBox(height: 24),
                      _buildResponsibilitiesSection(),
                      SizedBox(height: 24),
                      _buildAdditionalInfoSection(),
                      SizedBox(height: 24),
                      _buildProviderSection(),
                      SizedBox(height: 24), // Reduced from 32 to 24
                      _buildBookNowButton(),
                      SizedBox(height: 10), // Reduced from 20 to 10
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(Size size) {
    final List<String> images =
        (serviceData!['images'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      height: size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
      ),
      child: images.isEmpty
          ? Center(
        child: Icon(Icons.image, size: 80, color: Colors.grey[500]),
      )
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return _buildImageWithShimmer(images[index]);
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 16.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? highlightColor : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithShimmer(String imageUrl) {
    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
          ),
        ),
        // Using FadeInImage with precacheImage for better performance
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 800, // Set appropriate cache size for your needs
          cacheHeight: 600,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    serviceData!['name'] ?? 'Unnamed Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    serviceData!['category'] ?? 'N/A',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 10), // Added space before price
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: highlightColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${serviceData!['price']?.toString() ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: UserTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(124 reviews)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return SizedBox(
      width: 400, // Set a fixed width (adjust as needed)
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              serviceData!['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedSection() {
    final List<dynamic>? included = serviceData!['whatsIncluded'] as List<dynamic>?;

    if (included == null || included.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's Included",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          ...included.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibilitiesSection() {
    final List<dynamic>? responsibilities = serviceData!['responsibilities'] as List<dynamic>?;

    if (responsibilities == null || responsibilities.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsibilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          ...responsibilities.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'Flexible Scheduling',
            subtitle: 'Book at your convenient time',
          ),
          Divider(height: 24),
          _buildInfoItem(
            icon: Icons.verified_user,
            title: 'Verified Providers',
            subtitle: 'All providers are verified and trusted',
          ),
          Divider(height: 24),
          _buildInfoItem(
            icon: Icons.thumb_up,
            title: 'Satisfaction Guaranteed',
            subtitle: 'Quality service or money back',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection() {
    if (providerData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Provider',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerData!['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      providerData!['phone'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      providerData!['address']?['string'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () => _navigateToChat(context),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Message Provider',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showBookingSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: highlightColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Text(
          'Book Now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Generate dates for exactly one month from today
            List<DateTime> generateAvailableDates() {
              DateTime now = DateTime.now();

              // Create a date exactly one month from now
              DateTime oneMonthLater;
              if (now.month == 12) {
                oneMonthLater = DateTime(now.year + 1, 1, now.day);
              } else {
                oneMonthLater = DateTime(now.year, now.month + 1, now.day);
              }

              // Handle cases where the day doesn't exist in the target month
              if (oneMonthLater.day != now.day) {
                oneMonthLater =
                    DateTime(oneMonthLater.year, oneMonthLater.month, 0);
              }

              List<DateTime> dates = [];
              DateTime current = now;

              while (current.isBefore(oneMonthLater) ||
                  (current.day == oneMonthLater.day &&
                      current.month == oneMonthLater.month &&
                      current.year == oneMonthLater.year)) {
                dates.add(current);
                current = current.add(Duration(days: 1));
              }

              return dates;
            }

            List<DateTime> availableDates = generateAvailableDates();

            List<String> getTimeSlots() {
              List<String> timeSlots = [];
              DateTime now = DateTime.now();
              DateTime startTime;

              // If selected date is today, start from next available time slot
              if (selectedDate != null &&
                  selectedDate!.year == now.year &&
                  selectedDate!.month == now.month &&
                  selectedDate!.day == now.day) {
                // Round up to next 30-minute slot
                int nextMinute = now.minute >= 30 ? 0 : 30;
                int nextHour = now.minute >= 30 ? now.hour + 1 : now.hour;
                startTime = DateTime(
                    now.year, now.month, now.day, nextHour, nextMinute);
              } else if (selectedDate != null) {
                // For future dates, start from 9 AM
                startTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    9, 0
                );
              } else {
                return [];
              }

              // End time is 7:30 PM on selected date
              DateTime endTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  19, 30
              );

              // Generate 30-minute slots
              while (startTime.isBefore(endTime)) {
                String formattedTime =
                    '${startTime.hour > 12 ? startTime.hour - 12 : startTime
                    .hour == 0 ? 12 : startTime.hour}:${startTime.minute == 0
                    ? '00'
                    : '30'} ${startTime.hour >= 12 ? 'PM' : 'AM'}';
                timeSlots.add(formattedTime);
                startTime = startTime.add(Duration(minutes: 30));
              }

              return timeSlots;
            }

            // Format date for header display
            String getFormattedDate(DateTime date) {
              final months = [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December'
              ];
              return '${date.day} ${months[date.month - 1]} ${date.year}';
            }

            return Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom handle bar
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16,
                                    color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  '45 min service duration',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Close button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.black54),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 32, thickness: 1, color: Colors.grey[200]),

                  // Date selection section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20,
                                color: Colors.indigo[700]),
                            SizedBox(width: 8),
                            Text(
                              'Select Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[700],
                              ),
                            ),
                            // Display selected date
                            if (selectedDate != null) ...[
                              Spacer(),
                              Text(
                                getFormattedDate(selectedDate!),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Calendar date selection
                  Container(
                    height: 100,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: availableDates.length,
                      itemBuilder: (context, index) {
                        DateTime date = availableDates[index];
                        bool isSelected = selectedDate != null &&
                            selectedDate!.day == date.day &&
                            selectedDate!.month == date.month;

                        // Check if date is today
                        bool isToday = date.day == DateTime
                            .now()
                            .day &&
                            date.month == DateTime
                                .now()
                                .month &&
                            date.year == DateTime
                                .now()
                                .year;

                        final dayNames = [
                          'Sun',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat'
                        ];
                        final monthNames = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec'
                        ];

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedDate = date;
                              selectedTime = null;
                            });
                          },
                          child: Container(
                            width: 70,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo[50] : Colors
                                  .white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNames[date.weekday % 7],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? Colors.indigo : Colors
                                        .grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.indigo
                                        : (isToday ? Colors.orange[50] : Colors
                                        .transparent),
                                    border: isToday && !isSelected
                                        ? Border.all(
                                        color: Colors.orange[300]!, width: 1)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isToday
                                            ? Colors.orange[700]
                                            : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  monthNames[date.month - 1],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.indigo : Colors
                                        .grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  // Time slot selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: Colors
                            .indigo[700]),
                        SizedBox(width: 8),
                        Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[700],
                          ),
                        ),
                        if (selectedTime != null) ...[
                          Spacer(),
                          Text(
                            '${selectedTime!.hour > 12
                                ? selectedTime!.hour - 12
                                : selectedTime!.hour}:${selectedTime!.minute ==
                                0 ? '00' : selectedTime!.minute} ${selectedTime!
                                .hour >= 12 ? 'PM' : 'AM'}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Time slots grid
                  Expanded(
                    child: selectedDate == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.date_range, size: 48,
                              color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            "Select a date to view available times",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : getTimeSlots().isEmpty
                        ? Center(
                      child: Text(
                        "No available time slots",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                        : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: getTimeSlots().length,
                        itemBuilder: (context, i) {
                          String timeSlot = getTimeSlots()[i];
                          bool isSelected = selectedTime ==
                              _parseTime(timeSlot);

                          return GestureDetector(
                            onTap: () {
                              setModalState(() =>
                              selectedTime = _parseTime(timeSlot));
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected ? Colors.indigo : Colors
                                    .white,
                                border: Border.all(
                                  color: isSelected ? Colors.indigo : Colors
                                      .grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                                    : null,
                              ),
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors
                                      .black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom action bar with confirmation button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: Offset(0, -4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Summary info
                        if (selectedDate != null && selectedTime != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your appointment',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${getFormattedDate(
                                      selectedDate!)} · ${selectedTime!.hour >
                                      12
                                      ? selectedTime!.hour - 12
                                      : selectedTime!.hour}:${selectedTime!
                                      .minute == 0 ? '00' : selectedTime!
                                      .minute} ${selectedTime!.hour >= 12
                                      ? 'PM'
                                      : 'AM'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Confirm button
                        ElevatedButton(
                          onPressed: selectedDate != null &&
                              selectedTime != null
                              ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConfirmBookingPage(
                                      date: selectedDate!,
                                      time: selectedTime!,
                                      serviceData: serviceData!,
                                      serviceId: widget.serviceId,
                                    ),
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedDate != null &&
                                selectedTime != null
                                ? Colors.indigo
                                : Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  }