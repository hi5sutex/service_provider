import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/ConfirmBookingPage.dart';
import 'package:service_provider/User%20Panel/chat_funtionality/chat_screen.dart';
import 'package:service_provider/theme.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId}) : super(key: key);

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

  Future<void> _fetchServiceAndProviderDetails() async {
    try {
      DocumentSnapshot serviceSnapshot =
      await _firestore.collection('services').doc(widget.serviceId).get();

      if (serviceSnapshot.exists) {
        serviceData = serviceSnapshot.data() as Map<String, dynamic>;
        String providerId = serviceData!['createdBy'];

        DocumentSnapshot providerSnapshot =
        await _firestore.collection('providers').doc(providerId).get();

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
            providerName: providerData!['name'],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.secondaryColorCustom, // White background
      appBar: AppBar(
        title: Text(
          serviceData?['name'] ?? 'Service Details',
          style: TextStyle(color: AppTheme.secondaryColorCustom),
        ),
        backgroundColor: AppTheme.primaryColorCustom,
        foregroundColor: AppTheme.secondaryColorCustom,
      ),
      body: serviceData == null
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColorCustom))
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSlider(),
              SizedBox(height: screenHeight * 0.02),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                elevation: 4,
                color: AppTheme.secondaryColorCustom, // White card
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceData!['name'] ?? 'Unnamed Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Category: ${serviceData!['category'] ?? 'N/A'}',
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: screenWidth * 0.04),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        '₹${serviceData!['price']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                          color: AppTheme.primaryColorCustom,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        serviceData!['description'] ?? 'No description available',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              if ((serviceData!['whatsIncluded'] as List<dynamic>?)?.isNotEmpty ?? false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  elevation: 4,
                  color: AppTheme.secondaryColorCustom, // White card
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's Included",
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ...(serviceData!['whatsIncluded'] as List<dynamic>).map(
                              (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.providerGreen),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(child: Text(item.toString())),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.03),
              if ((serviceData!['responsibilities'] as List<dynamic>?)?.isNotEmpty ?? false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  elevation: 4,
                  color: AppTheme.secondaryColorCustom, // White card
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsibilities',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ...(serviceData!['responsibilities'] as List<dynamic>).map(
                              (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_right, color: Colors.blue),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(child: Text(item.toString())),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.03),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                elevation: 4,
                color: AppTheme.secondaryColorCustom, // White card
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ListTile(
                        leading: Icon(Icons.access_time, color: Colors.blue),
                        title: Text('Flexible Scheduling'),
                        subtitle: Text('Book at your convenient time'),
                      ),
                      ListTile(
                        leading: Icon(Icons.verified_user, color: Colors.blue),
                        title: Text('Verified Providers'),
                        subtitle: Text('All providers are verified and trusted'),
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
              SizedBox(height: screenHeight * 0.03),
              if (providerData != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  elevation: 4,
                  color: AppTheme.secondaryColorCustom, // White card
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Provider',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
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
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _navigateToChat(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColorCustom,
                              foregroundColor: AppTheme.secondaryColorCustom,
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.015),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                            ),
                            child: Text('Message Provider'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.04),
              Center(
                child: ElevatedButton(
                  onPressed: _showBookingSheet,
                  child: Text('Book Now',
                      style: TextStyle(color: AppTheme.secondaryColorCustom)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A9AFF),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final List<String> images =
        (serviceData!['images'] as List<dynamic>?)?.cast<String>() ?? [];

    if (images.isEmpty) {
      return Container(
        height: screenHeight * 0.25,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        child: Center(
          child: Icon(Icons.image, size: screenWidth * 0.2, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.25,
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
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: screenWidth * 0.2, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              width: _currentPage == index ? screenWidth * 0.02 : screenWidth * 0.012,
              height: _currentPage == index ? screenWidth * 0.02 : screenWidth * 0.012,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<DateTime> availableDates = List.generate(
              DateTime(DateTime.now().year, DateTime.now().month + 2, 0).day -
                  DateTime.now().day +
                  1,
                  (index) => DateTime.now().add(Duration(days: index)),
            );

            List<String> getTimeSlots() {
              List<String> timeSlots = [];
              DateTime now = DateTime.now();
              DateTime startTime;

              if (selectedDate != null &&
                  selectedDate!.year == now.year &&
                  selectedDate!.month == now.month &&
                  selectedDate!.day == now.day) {
                int nextMinute = now.minute >= 30 ? 0 : 30;
                int nextHour = now.minute >= 30 ? now.hour + 1 : now.hour;
                startTime =
                    DateTime(now.year, now.month, now.day, nextHour, nextMinute);
              } else {
                startTime = DateTime(now.year, now.month, now.day, 9, 0);
              }

              DateTime endTime = DateTime(now.year, now.month, now.day, 19, 30);

              while (startTime.isBefore(endTime)) {
                String formattedTime =
                    '${startTime.hour > 12 ? startTime.hour - 12 : startTime.hour}:${startTime.minute == 0 ? '00' : '30'} ${startTime.hour >= 12 ? 'PM' : 'AM'}';
                if (!timeSlots.contains(formattedTime)) {
                  timeSlots.add(formattedTime);
                }
                startTime = startTime.add(Duration(minutes: 30));
              }
              return timeSlots;
            }

            return Container(
              height: screenHeight * 0.65,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColorCustom, // White bottom sheet
                borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Appointment Time',
                    style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: screenHeight * 0.006),
                  Text('Service will take approximately 45 minutes',
                      style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035)),
                  SizedBox(height: screenHeight * 0.025),
                  Text('Select a Date',
                      style: TextStyle(
                          fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                  SizedBox(height: screenHeight * 0.01),
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
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.012,
                                horizontal: screenWidth * 0.035),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              color: isSelected
                                  ? Colors.deepPurple[100]
                                  : Colors.grey.shade100,
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
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
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    isSelected ? Colors.deepPurple : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    isSelected ? Colors.deepPurple : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Text('Select Time Slot',
                      style: TextStyle(
                          fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: selectedDate == null
                        ? Center(
                        child: Text("Select a date first",
                            style: TextStyle(
                                color: Colors.grey, fontSize: screenWidth * 0.04)))
                        : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: screenWidth * 0.025,
                        mainAxisSpacing: screenHeight * 0.015,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: getTimeSlots().length,
                      itemBuilder: (context, i) {
                        String timeSlot = getTimeSlots()[i];
                        bool isSelected = selectedTime == _parseTime(timeSlot);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedTime = _parseTime(timeSlot));
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.012,
                                horizontal: screenWidth * 0.02),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              color:
                              isSelected ? Colors.deepPurple[100] : Colors.white,
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                    color: Colors.deepPurple.shade100,
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
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  ElevatedButton(
                    onPressed: selectedDate != null && selectedTime != null
                        ? () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmBookingPage(
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
                      backgroundColor: selectedDate != null && selectedTime != null
                          ? Colors.deepPurple
                          : Colors.grey[400],
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.017),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                      elevation: 5,
                    ),
                    child: Center(
                      child: Text(
                        'Confirm Booking',
                        style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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
  }
}