import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/ConfirmBookingPage.dart';

import 'chat_funtionality/chat_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchServiceAndProviderDetails();
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

  // chat added
  Future<DocumentSnapshot?> _findMatchingUser(String email) async {
    // Search in users collection
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (usersQuery.docs.isNotEmpty) {
      return usersQuery.docs.first;
    }

    // Search in providers collection
    final providersQuery = await FirebaseFirestore.instance
        .collection('providers')
        .where('email', isEqualTo: email)
        .get();

    if (providersQuery.docs.isNotEmpty) {
      return providersQuery.docs.first;
    }

    return null; // No match found
  } // ----------

  Future<void> _fetchServiceAndProviderDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        serviceData = serviceSnapshot.data() as Map<String, dynamic>;
        String providerId = serviceData!['createdBy'];

        DocumentSnapshot providerSnapshot = await FirebaseFirestore.instance
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          serviceData?['name'] ?? 'Service Details',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: Color(0xFF060644),
        foregroundColor: Colors.white,
      ),
      body: serviceData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSlider(),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceData!['name'] ?? 'Unnamed Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Category: ${serviceData!['category'] ?? 'N/A'}',
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '₹${serviceData!['price']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF060644),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        serviceData!['description'] ??
                            'No description available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              if ((serviceData!['whatsIncluded'] as List<dynamic>?)
                  ?.isNotEmpty ??
                  false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's Included",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...(serviceData!['whatsIncluded']
                        as List<dynamic>)
                            .map(
                              (item) =>
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(item.toString())),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),
              if ((serviceData!['responsibilities'] as List<dynamic>?)
                  ?.isNotEmpty ??
                  false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsibilities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...(serviceData!['responsibilities']
                        as List<dynamic>)
                            .map(
                              (item) =>
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_right,
                                        color: Colors.blue),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(item.toString())),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading:
                        Icon(Icons.access_time, color: Colors.blue),
                        title: Text('Flexible Scheduling'),
                        subtitle: Text('Book at your convenient time'),
                      ),
                      ListTile(
                        leading:
                        Icon(Icons.verified_user, color: Colors.blue),
                        title: Text('Verified Providers'),
                        subtitle: Text(
                            'All providers are verified and trusted'),
                      ),
                      ListTile(
                        leading: Icon(Icons.thumb_up, color: Colors.blue),
                        title: Text('Satisfaction Guaranteed'),
                        subtitle: Text('Quality service or money back'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              // chat added
              if (providerData != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Provider',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(providerData!['name'] ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(providerData!['phone'] ?? 'N/A'),
                              Text(providerData!['email'] ?? 'N/A'),
                              Text(providerData!['address']?['string'] ?? 'N/A'),
                            ],
                          ),
                        ),
                        // Add the Chat Button if email matches
                        // if (providerData!['email'] != null)
                        if (providerData!['email'] != null)
                          FutureBuilder<DocumentSnapshot?>(
                            future: _findMatchingUser(providerData!['email']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasData && snapshot.data != null) {
                                final matchedUserId = snapshot.data!.id;
                                final currentUser = _auth.currentUser;

                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            userId: currentUser!.uid, // Current user's ID
                                            receiverId: matchedUserId, // Receiver's ID
                                            senderEmail: currentUser.email!, // Current user's email
                                            receiverEmail: providerData!['email'], // Receiver's email
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('Message'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xffffffff),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox.shrink(); // No match found
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              // chat added
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _showBookingSheet,
                  child: Text('Book Now',
                      style: TextStyle(color: Color(0xffffffff))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A9AFF),
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    final List<String> images =
        (serviceData!['images'] as List<dynamic>?)?.cast<String>() ?? [];

    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: _currentPage == index ? 8.0 : 5.0,
              height: _currentPage == index ? 8.0 : 5.0,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) { // Added builder parameter
        return StatefulBuilder(
          builder: (context, setModalState) { // Added builder parameter
            List<DateTime> availableDates = List.generate(
              DateTime(DateTime
                  .now()
                  .year, DateTime
                  .now()
                  .month + 2, 0).day - DateTime
                  .now()
                  .day + 1,
                  (index) => DateTime.now().add(Duration(days: index)),
            );

            List<String> getTimeSlots() {
              List<String> timeSlots = [];
              DateTime now = DateTime.now();
              DateTime startTime;

              if (selectedDate != null && selectedDate!.year == now.year &&
                  selectedDate!.month == now.month &&
                  selectedDate!.day == now.day) {
                int nextMinute = now.minute >= 30 ? 0 : 30;
                int nextHour = now.minute >= 30 ? now.hour + 1 : now.hour;
                startTime = DateTime(
                    now.year, now.month, now.day, nextHour, nextMinute);
              } else {
                startTime = DateTime(now.year, now.month, now.day, 9, 0);
              }

              DateTime endTime = DateTime(now.year, now.month, now.day, 19, 30);

              while (startTime.isBefore(endTime)) {
                String formattedTime = '${startTime.hour > 12 ? startTime.hour -
                    12 : startTime.hour}:${startTime.minute == 0
                    ? '00'
                    : '30'} ${startTime.hour >= 12 ? 'PM' : 'AM'}';
                if (!timeSlots.contains(formattedTime)) {
                  timeSlots.add(formattedTime);
                }
                startTime = startTime.add(Duration(minutes: 30));
              }
              return timeSlots;
            }

            return Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.65,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Appointment Time',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: 5),
                  Text('Service will take approximately 45 minutes',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  SizedBox(height: 20),
                  Text('Select a Date', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableDates.map((date) {
                        bool isSelected = selectedDate != null &&
                            selectedDate!.day == date.day &&
                            selectedDate!.month == date.month;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedDate = date;
                              selectedTime = null;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 6),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: isSelected ? Colors.deepPurple : Colors
                                      .grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.deepPurple[100]
                                  : Colors.grey.shade100,
                              boxShadow: [
                                if (isSelected) BoxShadow(
                                    color: Colors.deepPurple.shade100,
                                    blurRadius: 5,
                                    spreadRadius: 1)
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  [
                                    'Sun',
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat'
                                  ][date.weekday % 7],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Select Time Slot', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Expanded(
                    child: selectedDate == null
                        ? Center(
                        child: Text("Select a date first", style: TextStyle(
                            color: Colors.grey, fontSize: 16)))
                        : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: getTimeSlots().length,
                      itemBuilder: (context, i) {
                        String timeSlot = getTimeSlots()[i];
                        bool isSelected = selectedTime == _parseTime(timeSlot);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() =>
                            selectedTime = _parseTime(timeSlot));
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isSelected
                                  ? Colors.deepPurple[100]
                                  : Colors.white,
                              border: Border.all(
                                  color: isSelected ? Colors.deepPurple : Colors
                                      .grey.shade300),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(color: Colors.deepPurple.shade100,
                                    blurRadius: 5,
                                    spreadRadius: 1)
                              ]
                                  : [],
                            ),
                            child: Text(
                              timeSlot,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.deepPurple[900]
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: selectedDate != null && selectedTime != null
                        ? () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConfirmBookingPage(
                                date: selectedDate!,
                                time: selectedTime!,
                                // Pass the selectedTime as TimeOfDay
                                serviceData: serviceData!,
                                serviceId: widget.serviceId,
                              ),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedDate != null &&
                          selectedTime != null ? Colors.deepPurple : Colors
                          .grey[400],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: Center(
                      child: Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight
                            .bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } }