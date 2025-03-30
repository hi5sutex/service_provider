import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class AddDummyData extends StatefulWidget {
  const AddDummyData({super.key});

  @override
  State<AddDummyData> createState() => _AddDummyDataState();
}

class _AddDummyDataState extends State<AddDummyData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Function to generate random timestamp from last 2 months
  Timestamp getRandomTimestamp() {
    DateTime now = DateTime.now();
    DateTime twoMonthsAgo = now.subtract(const Duration(days: 60));
    // Calculate difference in days instead of milliseconds to avoid overflow
    int diffDays = now.difference(twoMonthsAgo).inDays;
    int randomDays = _random.nextInt(diffDays + 1); // +1 to include the full range
    return Timestamp.fromDate(
      twoMonthsAgo.add(Duration(days: randomDays)),
    );
  }

  // Generic function to add data to Firestore
  Future<void> addDataToFirestore(String collection, Map<String, dynamic> data, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
      print('Added to $collection: $docId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to $collection successfully!')),
      );
    } catch (e) {
      print('Error adding to $collection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to $collection: $e')),
      );
    }
  }

  // Add dummy users with specific data
  void addDummyUsers() {
    final userIds = [
      'G8mLX0uCo4WGILN5lcQkgTXaRzA2',
      'rkTHPMayZHRzJBMZDM5lhxtSJ9J2',
      'fEcoSeK1wGeAKy9BCYoZ3MtunVU2',
      'uB1uZVpbjMgbWfc8ySONtOzo9sR2',
    ];

    final users = [
      {
        'createdAt': getRandomTimestamp(),
        'email': 'axay6969@gmail.com',
        'name': 'Axay',
        'phone': '8320166224',
        'profileImage': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735235662/1000117310_sg7kxn.png',
        'userType': 'user',
      },
      {
        'createdAt': getRandomTimestamp(),
        'email': 'john.doe@gmail.com',
        'name': 'John Doe',
        'phone': '9876543210',
        'profileImage': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735235662/1000117310_sg7kxn.png',
        'userType': 'user',
      },
      {
        'createdAt': getRandomTimestamp(),
        'email': 'jane.smith@gmail.com',
        'name': 'Jane Smith',
        'phone': '9123456789',
        'profileImage': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735235662/1000117310_sg7kxn.png',
        'userType': 'user',
      },
      {
        'createdAt': getRandomTimestamp(),
        'email': 'mary.jones@gmail.com',
        'name': 'Mary Jones',
        'phone': '9988776655',
        'profileImage': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735235662/1000117310_sg7kxn.png',
        'userType': 'user',
      },
    ];

    for (int i = 0; i < userIds.length; i++) {
      addDataToFirestore('users', users[i], userIds[i]);
    }
  }

// Add dummy providers with specific data
  void addDummyProviders() {
    final providerIds = [
      'zgTIJfW1FNPKD4ShvNUjoCItnLs1',
      '1zTIfICxiEbbqrlWmDJVXhbLmet1',
      'uxn0mtnOsBTjP8T1ds9Q7VsbCDH2',
    ];

    final providers = [
      {
        'address': {
          'latitude': 21.2644792,
          'longitude': 72.855722,
          'string': 'Chhaprabhatha, Adajan Taluka, Surat, Gujarat, 394107, India',
        },
        'bio': 'Hula la la',
        'createdAt': getRandomTimestamp(),
        'email': 'mirih76399@myweblaw.com',
        'name': 'Ajju Baba',
        'phone': '9785463223',
        'profileImage': 'https://avatar.iran.liara.run/public',
        'servicesOffered': <String>[], // Empty array
        'userType': 'provider',
      },
      {
        'address': {
          'latitude': 21.1702401,
          'longitude': 72.8310607,
          'string': 'Katargam, Surat, Gujarat, 395004, India',
        },
        'bio': 'Experienced service provider',
        'createdAt': getRandomTimestamp(),
        'email': 'provider2@services.com',
        'name': 'Provider Two',
        'phone': '8765432109',
        'profileImage': 'https://avatar.iran.liara.run/public',
        'servicesOffered': <String>[], // Empty array
        'userType': 'provider',
      },
      {
        'address': {
          'latitude': 21.195923,
          'longitude': 72.819444,
          'string': 'Adajan, Surat, Gujarat, 395009, India',
        },
        'bio': 'Reliable and professional',
        'createdAt': getRandomTimestamp(),
        'email': 'provider3@services.com',
        'name': 'Provider Three',
        'phone': '7654321098',
        'profileImage': 'https://avatar.iran.liara.run/public',
        'servicesOffered': <String>[], // Empty array
        'userType': 'provider',
      },
    ];

    for (int i = 0; i < providerIds.length; i++) {
      addDataToFirestore('providers', providers[i], providerIds[i]);
    }
  }

  // Add dummy admins with specific data
  void addDummyAdmins() {
    final adminIds = [
      '4qBD4qnwnEcwGWiGlDTF3v64Twn2',
      'eJgcrhxbMpPCzxbGrQSVUMWG9Pw2',
    ];

    final admins = [
      {
        'email': 'admin@gmail.com',
        'fcmToken': 'd8ZQg9MTSYyiv8Re9XdgtL:APA91bEkbpf5u_yrmdG8h55IKrv73e-3rzlz_U2qYjbp0JvWa5u9JFDf2umgnSIbcFgobQzQTVxF24e2saQD2V2TfWkMCpL3NVDoZE5zoMcS7l1KZuS9_OY',
        'imageUrl': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735207125/businessman_wthcmd.png',
        'name': 'Admin',
        'password': 'admin@123',
        'permissions': {
          'manageBookings': true,
          'manageCategories': true,
          'managePayments': true,
          'manageProviders': true,
          'manageServices': true,
          'manageUsers': true,
          'sendNotifications': true,
          'viewAnalytics': true,
          'viewBookings': true,
          'viewPayments': true,
          'viewProviders': true,
          'viewServices': true,
          'viewUsers': true,
        },
        'userType': 'admin',
      },
      {
        'email': 'superadmin@gmail.com',
        'fcmToken': 'd8ZQg9MTSYyiv8Re9XdgtL:APA91bEkbpf5u_yrmdG8h55IKrv73e-3rzlz_U2qYjbp0JvWa5u9JFDf2umgnSIbcFgobQzQTVxF24e2saQD2V2TfWkMCpL3NVDoZE5zoMcS7l1KZuS9_OY',
        'imageUrl': 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735207125/businessman_wthcmd.png',
        'name': 'Super Admin',
        'password': 'super@123',
        'permissions': {
          'manageBookings': true,
          'manageCategories': true,
          'managePayments': true,
          'manageProviders': true,
          'manageServices': true,
          'manageUsers': true,
          'sendNotifications': true,
          'viewAnalytics': true,
          'viewBookings': true,
          'viewPayments': true,
          'viewProviders': true,
          'viewServices': true,
          'viewUsers': true,
        },
        'userType': 'admin',
      },
    ];

    for (int i = 0; i < adminIds.length; i++) {
      addDataToFirestore('admins', admins[i], adminIds[i]);
    }
  }

  // Add dummy bookings
// Add dummy bookings
  void addDummyBookings() async {
    final userIds = [
      'G8mLX0uCo4WGILN5lcQkgTXaRzA2',
      'rkTHPMayZHRzJBMZDM5lhxtSJ9J2',
      'fEcoSeK1wGeAKy9BCYoZ3MtunVU2',
      'uB1uZVpbjMgbWfc8ySONtOzo9sR2',
    ];

    final providerIds = [
      'zgTIJfW1FNPKD4ShvNUjoCItnLs1', // Ajju Baba
      '1zTIfICxiEbbqrlWmDJVXhbLmet1', // Provider Two
      'uxn0mtnOsBTjP8T1ds9Q7VsbCDH2', // Provider Three
    ];

    final locations = [
      {'latitude': 21.1702401, 'longitude': 72.8310607, 'local': 'Katargam, Surat, Gujarat, 395004, India'},
      {'latitude': 21.195923, 'longitude': 72.819444, 'local': 'Adajan, Surat, Gujarat, 395009, India'},
      {'latitude': 21.2644792, 'longitude': 72.855722, 'local': 'Chhaprabhatha, Adajan Taluka, Surat, Gujarat, 394107, India'},
      {'latitude': 21.2271247, 'longitude': 72.834477, 'local': 'Laxmikant Ashram Road, Katargam Taluka, Surat, Gujarat, 395004, India'},
    ];

    // Generate random timestamp for bookingDate (last 1 month)
    Timestamp getRandomBookingTimestamp() {
      DateTime now = DateTime.now();
      DateTime oneMonthAgo = now.subtract(const Duration(days: 30));
      int diffDays = now.difference(oneMonthAgo).inDays;
      int randomDays = _random.nextInt(diffDays + 1);
      return Timestamp.fromDate(oneMonthAgo.add(Duration(days: randomDays)));
    }

    // Generate random timestamp for serviceDate (future 1 month from today)
    Timestamp getRandomServiceTimestamp() {
      DateTime now = DateTime.now();
      DateTime oneMonthFuture = now.add(const Duration(days: 30));
      int diffDays = oneMonthFuture.difference(now).inDays;
      int randomDays = _random.nextInt(diffDays + 1);
      return Timestamp.fromDate(now.add(Duration(days: randomDays)));
    }

    // Generate unique payment ID
    String generatePaymentId() {
      return 'pay_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
    }

    try {
      // Fetch all services offered by providers
      List<Map<String, dynamic>> allServices = [];

      for (String providerId in providerIds) {
        // Get provider document
        DocumentSnapshot providerDoc = await _firestore.collection('providers').doc(providerId).get();
        if (providerDoc.exists) {
          List<dynamic> servicesOffered = providerDoc['servicesOffered'] ?? [];

          // Fetch each service from 'services' collection
          for (String serviceId in servicesOffered) {
            DocumentSnapshot serviceDoc = await _firestore.collection('services').doc(serviceId).get();
            if (serviceDoc.exists) {
              allServices.add({
                'id': serviceId,
                'name': serviceDoc['name'],
                'price': serviceDoc['price'],
                'providerId': providerId,
              });
            }
          }
        }
      }

      if (allServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No services found for providers!')),
        );
        return;
      }

      // Generate 30 bookings using fetched services
      final bookings = List.generate(30, (index) {
        final service = allServices[_random.nextInt(allServices.length)];
        final providerId = service['providerId'] as String;
        final servicePrice = service['price'] as int;
        final platformFee = (servicePrice * 0.01).round(); // 1% platform fee
        final taxAmount = (servicePrice * 0.11).round(); // 11% tax
        final paymentAmount = servicePrice + platformFee + taxAmount;

        return {
          'bookingDate': getRandomBookingTimestamp(),
          'clearedAt': null,
          'isNotificationCleared': false,
          'location': locations[_random.nextInt(locations.length)],
          'paymentAmount': paymentAmount,
          'paymentId': generatePaymentId(),
          'paymentMode': 'Debit Card',
          'paymentStatus': 'Completed',
          'providerId': providerId,
          'serviceDate': getRandomServiceTimestamp(),
          'serviceId': service['id'],
          'serviceName': service['name'],
          'status': 'Pending',
          'userId': userIds[_random.nextInt(userIds.length)],
        };
      });

      // Add bookings and corresponding earnings
      for (var booking in bookings) {
        // Add the booking and get the document reference
        DocumentReference bookingRef = await _firestore.collection('bookings').add(booking);
        String bookingId = bookingRef.id;

        // Calculate earnings details
        final servicePrice = allServices.firstWhere((s) => s['id'] == booking['serviceId'])['price'] as int;
        final platformFee = (servicePrice * 0.01).round();
        final taxAmount = (servicePrice * 0.11).round();
        final paymentAmount = servicePrice + platformFee + taxAmount;

        // Add earnings record
        await _firestore
            .collection('earnings')
            .doc(booking['providerId'] as String)
            .collection('records')
            .add({
          'earningStatus': 'Pending',
          'paymentAmount': paymentAmount,
          'paymentAt': booking['bookingDate'],
          'paymentId': booking['paymentId'],
          'platformFee': platformFee,
          'serviceAmount': servicePrice,
          'taxAmount': taxAmount,
        });

        print('Added booking $bookingId and earnings for provider ${booking['providerId']}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('30 Bookings added successfully!')),
      );
    } catch (e) {
      print('Error adding bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add bookings: $e')),
      );
    }
  }

// Add dummy services
  void addDummyServices() async {
    final providerIds = [
      'zgTIJfW1FNPKD4ShvNUjoCItnLs1', // Ajju Baba
      '1zTIfICxiEbbqrlWmDJVXhbLmet1', // Provider Two
      'uxn0mtnOsBTjP8T1ds9Q7VsbCDH2', // Provider Three
    ];

    final services = [
      // Services for Provider 1 (zgTIJfW1FNPKD4ShvNUjoCItnLs1)
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Thorough house cleaning service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'House Cleaning',
        'price': 1000,
        'responsibilities': ['Dusting', 'Vacuuming', 'Mopping'],
        'subcategory': 'House Cleaning',
        'whatsIncluded': ['Cleaning supplies', 'Equipment'],
      },
      {
        'category': 'Gardening',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Lawn mowing and trimming.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Lawn Mowing',
        'price': 800,
        'responsibilities': ['Grass cutting', 'Edging'],
        'subcategory': 'Lawn Mowing',
        'whatsIncluded': ['Mower', 'Cleanup'],
      },
      {
        'category': 'Painting',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Interior wall painting.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Interior Painting',
        'price': 2500,
        'responsibilities': ['Surface prep', 'Painting'],
        'subcategory': 'Interior Painting',
        'whatsIncluded': ['Paint', 'Brushes'],
      },
      {
        'category': 'Plumbing',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Leak repair service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Leak Fixing',
        'price': 900,
        'responsibilities': ['Leak detection', 'Sealing'],
        'subcategory': 'Leak Fixing',
        'whatsIncluded': ['Sealant', 'Tools'],
      },
      {
        'category': 'Electrical',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Fan installation service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Fan Installation',
        'price': 700,
        'responsibilities': ['Mounting', 'Wiring'],
        'subcategory': 'Fan Installation',
        'whatsIncluded': ['Fan mount', 'Wires'],
      },

      // Services for Provider 2 (1zTIfICxiEbbqrlWmDJVXhbLmet1)
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Professional makeup application.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Makeup Services',
        'price': 1500,
        'responsibilities': ['Face makeup', 'Eye makeup'],
        'subcategory': 'Makeup Services',
        'whatsIncluded': ['Foundation', 'Eyeliner'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Washing machine repair.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Washing Machine Repair',
        'price': 1200,
        'responsibilities': ['Drum check', 'Motor repair'],
        'subcategory': 'Washing Machine Repair',
        'whatsIncluded': ['Parts', 'Tools'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Oil change for vehicles.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Oil Change',
        'price': 800,
        'responsibilities': ['Oil drain', 'Filter change'],
        'subcategory': 'Oil Change',
        'whatsIncluded': ['Oil', 'Filter'],
      },
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Birthday party decoration.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Birthday Party Decoration',
        'price': 2000,
        'responsibilities': ['Setup', 'Decoration'],
        'subcategory': 'Birthday Party Decoration',
        'whatsIncluded': ['Balloons', 'Banners'],
      },
      {
        'category': 'Home Improvement',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Carpentry for custom furniture.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Carpentry',
        'price': 1800,
        'responsibilities': ['Wood cutting', 'Assembly'],
        'subcategory': 'Carpentry',
        'whatsIncluded': ['Wood', 'Tools'],
      },

      // Services for Provider 3 (uxn0mtnOsBTjP8T1ds9Q7VsbCDH2)
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Fitness training at home.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Fitness Trainer',
        'price': 2000,
        'responsibilities': ['Workout plan', 'Training'],
        'subcategory': 'Fitness Trainer',
        'whatsIncluded': ['Session', 'Diet tips'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Air conditioner servicing.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Air Conditioner Repair',
        'price': 1500,
        'responsibilities': ['Filter cleaning', 'Gas refill'],
        'subcategory': 'Air Conditioner Repair',
        'whatsIncluded': ['Tools', 'Gas'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Tire replacement service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Tire Replacement',
        'price': 2000,
        'responsibilities': ['Tire fitting', 'Alignment'],
        'subcategory': 'Tire Replacement',
        'whatsIncluded': ['Tire', 'Balancing'],
      },
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Carpet cleaning service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Carpet Cleaning',
        'price': 1200,
        'responsibilities': ['Steam cleaning', 'Stain removal'],
        'subcategory': 'Carpet Cleaning',
        'whatsIncluded': ['Solution', 'Equipment'],
      },
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Event photography service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Event Photography',
        'price': 2500,
        'responsibilities': ['Shooting', 'Editing'],
        'subcategory': 'Event Photography',
        'whatsIncluded': ['Photos', 'Digital copies'],
      },
    ];

    try {
      for (var service in services) {
        // Add the service and get the document reference
        DocumentReference docRef = await _firestore.collection('services').add(service);
        String serviceId = docRef.id;

        // Update the provider's servicesOffered array
        Object? providerId = service['createdBy'];
        await _firestore.collection('providers').doc(providerId as String?).update({
          'servicesOffered': FieldValue.arrayUnion([serviceId]),
        });

        print('Added service $serviceId and updated provider $providerId');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('15 Services added successfully!')),
      );
    } catch (e) {
      print('Error adding services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add services: $e')),
      );
    }
  }

// Add dummy pending services
  void addDummyPendingServices() async {
    final providerIds = [
      'zgTIJfW1FNPKD4ShvNUjoCItnLs1', // Ajju Baba
      '1zTIfICxiEbbqrlWmDJVXhbLmet1', // Provider Two
      'uxn0mtnOsBTjP8T1ds9Q7VsbCDH2', // Provider Three
    ];

    final pendingServices = [
      // Beauty & Wellness
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Professional manicure and pedicure service at home.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Manicure & Pedicure',
        'price': 500,
        'responsibilities': ['Nail trimming', 'Polish application'],
        'status': 'pending',
        'subcategory': 'Manicure & Pedicure',
        'whatsIncluded': ['Nail polish', 'Cuticle care'],
      },
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Expert makeup for special occasions.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Makeup Services',
        'price': 1500,
        'responsibilities': ['Face makeup', 'Eye makeup'],
        'status': 'pending',
        'subcategory': 'Makeup Services',
        'whatsIncluded': ['Foundation', 'Eyeliner', 'Lipstick'],
      },
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Personal fitness training sessions.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Fitness Trainer',
        'price': 2000,
        'responsibilities': ['Workout planning', 'Diet advice'],
        'status': 'pending',
        'subcategory': 'Fitness Trainer',
        'whatsIncluded': ['1-hour session', 'Fitness plan'],
      },

      // Appliance Repair
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Fixing refrigerator cooling issues.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Refrigerator Repair',
        'price': 1000,
        'responsibilities': ['Coolant check', 'Compressor repair'],
        'status': 'pending',
        'subcategory': 'Refrigerator Repair',
        'whatsIncluded': ['Inspection', 'Basic parts'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Washing machine maintenance and repair.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Washing Machine Repair',
        'price': 1200,
        'responsibilities': ['Drum check', 'Motor repair'],
        'status': 'pending',
        'subcategory': 'Washing Machine Repair',
        'whatsIncluded': ['Cleaning', 'Parts replacement'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'AC unit servicing and repair.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Air Conditioner Repair',
        'price': 1500,
        'responsibilities': ['Filter cleaning', 'Gas refill'],
        'status': 'pending',
        'subcategory': 'Air Conditioner Repair',
        'whatsIncluded': ['Full inspection', 'Cooling test'],
      },

      // Automobile Services
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Engine diagnostics and repair.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Engine Repair',
        'price': 3000,
        'responsibilities': ['Engine tuning', 'Parts replacement'],
        'status': 'pending',
        'subcategory': 'Engine Repair',
        'whatsIncluded': ['Oil check', 'Engine test'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Quick oil change service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Oil Change',
        'price': 800,
        'responsibilities': ['Oil drain', 'Filter replacement'],
        'status': 'pending',
        'subcategory': 'Oil Change',
        'whatsIncluded': ['New oil', 'Filter'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Tire replacement and alignment.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Tire Replacement',
        'price': 2000,
        'responsibilities': ['Tire fitting', 'Wheel alignment'],
        'status': 'pending',
        'subcategory': 'Tire Replacement',
        'whatsIncluded': ['New tire', 'Balancing'],
      },

      // Cleaning
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Deep house cleaning service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'House Cleaning',
        'price': 1000,
        'responsibilities': ['Dusting', 'Vacuuming'],
        'status': 'pending',
        'subcategory': 'House Cleaning',
        'whatsIncluded': ['Cleaning supplies', 'Mopping'],
      },
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Professional carpet cleaning.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Carpet Cleaning',
        'price': 1200,
        'responsibilities': ['Stain removal', 'Steam cleaning'],
        'status': 'pending',
        'subcategory': 'Carpet Cleaning',
        'whatsIncluded': ['Cleaning solution', 'Vacuuming'],
      },

      // Electrical
      {
        'category': 'Electrical',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Complete house wiring service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Wiring',
        'price': 2500,
        'responsibilities': ['Wire installation', 'Safety check'],
        'status': 'pending',
        'subcategory': 'Wiring',
        'whatsIncluded': ['Wires', 'Switches'],
      },
      {
        'category': 'Electrical',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Fan installation and repair.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Fan Installation & Repair',
        'price': 800,
        'responsibilities': ['Fan fitting', 'Motor check'],
        'status': 'pending',
        'subcategory': 'Fan Installation & Repair',
        'whatsIncluded': ['Mounting', 'Wiring'],
      },

      // Events & Decor
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Birthday party decoration service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Birthday Party Decoration',
        'price': 3000,
        'responsibilities': ['Setup', 'Cleanup'],
        'status': 'pending',
        'subcategory': 'Birthday Party Decoration',
        'whatsIncluded': ['Balloons', 'Banners'],
      },
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Professional event photography.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Event Photography',
        'price': 2500,
        'responsibilities': ['Photo shoot', 'Editing'],
        'status': 'pending',
        'subcategory': 'Event Photography',
        'whatsIncluded': ['50 photos', 'Digital copies'],
      },

      // Gardening
      {
        'category': 'Gardening',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Lawn mowing and maintenance.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Lawn Mowing',
        'price': 700,
        'responsibilities': ['Grass cutting', 'Edging'],
        'status': 'pending',
        'subcategory': 'Lawn Mowing',
        'whatsIncluded': ['Mowing', 'Cleanup'],
      },
      {
        'category': 'Gardening',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Weed removal from garden.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Weed Removal',
        'price': 600,
        'responsibilities': ['Weed pulling', 'Disposal'],
        'status': 'pending',
        'subcategory': 'Weed Removal',
        'whatsIncluded': ['Tools', 'Weed killer'],
      },

      // Home Improvement
      {
        'category': 'Home Improvement',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Custom carpentry work.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Carpentry',
        'price': 2000,
        'responsibilities': ['Wood cutting', 'Assembly'],
        'status': 'pending',
        'subcategory': 'Carpentry',
        'whatsIncluded': ['Wood', 'Nails'],
      },
      {
        'category': 'Home Improvement',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Wall repair and plastering.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Wall Repair',
        'price': 1500,
        'responsibilities': ['Patching', 'Smoothing'],
        'status': 'pending',
        'subcategory': 'Wall Repair',
        'whatsIncluded': ['Plaster', 'Tools'],
      },

      // Painting
      {
        'category': 'Painting',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Interior house painting.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Interior Painting',
        'price': 3000,
        'responsibilities': ['Wall prep', 'Painting'],
        'status': 'pending',
        'subcategory': 'Interior Painting',
        'whatsIncluded': ['Paint', 'Brushes'],
      },
      {
        'category': 'Painting',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Exterior house painting.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Exterior Painting',
        'price': 4000,
        'responsibilities': ['Surface prep', 'Painting'],
        'status': 'pending',
        'subcategory': 'Exterior Painting',
        'whatsIncluded': ['Paint', 'Ladder'],
      },

      // Plumbing
      {
        'category': 'Plumbing',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Fixing pipe leaks.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Leak Fixing',
        'price': 900,
        'responsibilities': ['Leak detection', 'Sealing'],
        'status': 'pending',
        'subcategory': 'Leak Fixing',
        'whatsIncluded': ['Sealant', 'Tools'],
      },
      {
        'category': 'Plumbing',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'New pipe installation.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Pipe Installation',
        'price': 1200,
        'responsibilities': ['Pipe fitting', 'Testing'],
        'status': 'pending',
        'subcategory': 'Pipe Installation',
        'whatsIncluded': ['Pipes', 'Fittings'],
      },

      // Additional Services (to reach 40)
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Haircut service at home.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Haircut at Home',
        'price': 400,
        'responsibilities': ['Hair cutting', 'Cleanup'],
        'status': 'pending',
        'subcategory': 'Haircut at Home',
        'whatsIncluded': ['Scissors', 'Comb'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'TV repair service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'TV Repair',
        'price': 800,
        'responsibilities': ['Screen check', 'Circuit repair'],
        'status': 'pending',
        'subcategory': 'TV Repair',
        'whatsIncluded': ['Tools', 'Basic parts'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Vehicle detailing service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Vehicle Detailing',
        'price': 1500,
        'responsibilities': ['Washing', 'Polishing'],
        'status': 'pending',
        'subcategory': 'Vehicle Detailing',
        'whatsIncluded': ['Wax', 'Cleaning supplies'],
      },
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Post-construction cleaning.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Post-construction Cleaning',
        'price': 2000,
        'responsibilities': ['Debris removal', 'Sweeping'],
        'status': 'pending',
        'subcategory': 'Post-construction Cleaning',
        'whatsIncluded': ['Brooms', 'Dustpans'],
      },
      {
        'category': 'Electrical',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Power backup setup service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Power Backup Setup',
        'price': 3000,
        'responsibilities': ['Inverter installation', 'Battery setup'],
        'status': 'pending',
        'subcategory': 'Power Backup Setup',
        'whatsIncluded': ['Wiring', 'Battery'],
      },
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Balloon decoration for events.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Balloon Decoration',
        'price': 1000,
        'responsibilities': ['Balloon setup', 'Arrangement'],
        'status': 'pending',
        'subcategory': 'Balloon Decoration',
        'whatsIncluded': ['Balloons', 'Helium'],
      },
      {
        'category': 'Gardening',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Plant trimming service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Plant Trimming',
        'price': 500,
        'responsibilities': ['Trimming', 'Cleanup'],
        'status': 'pending',
        'subcategory': 'Plant Trimming',
        'whatsIncluded': ['Shears', 'Disposal'],
      },
      {
        'category': 'Home Improvement',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Furniture assembly service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Furniture Assembly',
        'price': 1000,
        'responsibilities': ['Assembly', 'Alignment'],
        'status': 'pending',
        'subcategory': 'Furniture Assembly',
        'whatsIncluded': ['Tools', 'Instructions'],
      },
      {
        'category': 'Painting',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Fence painting service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Fence Painting',
        'price': 1500,
        'responsibilities': ['Prep', 'Painting'],
        'status': 'pending',
        'subcategory': 'Fence Painting',
        'whatsIncluded': ['Paint', 'Brushes'],
      },
      {
        'category': 'Plumbing',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Drain cleaning service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Drain Cleaning',
        'price': 700,
        'responsibilities': ['Clog removal', 'Cleaning'],
        'status': 'pending',
        'subcategory': 'Drain Cleaning',
        'whatsIncluded': ['Tools', 'Chemicals'],
      },
      {
        'category': 'Beauty & Wellness',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Yoga training sessions.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Yoga Trainer',
        'price': 1200,
        'responsibilities': ['Pose teaching', 'Breathing exercises'],
        'status': 'pending',
        'subcategory': 'Yoga Trainer',
        'whatsIncluded': ['Mat', '1-hour session'],
      },
      {
        'category': 'Appliance Repair',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Microwave repair service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Microwave Repair',
        'price': 900,
        'responsibilities': ['Heating check', 'Circuit repair'],
        'status': 'pending',
        'subcategory': 'Microwave Repair',
        'whatsIncluded': ['Tools', 'Parts'],
      },
      {
        'category': 'Automobile Services',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'AC service for vehicles.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'AC Service',
        'price': 1200,
        'responsibilities': ['Gas refill', 'Cooling check'],
        'status': 'pending',
        'subcategory': 'AC Service',
        'whatsIncluded': ['Gas', 'Tools'],
      },
      {
        'category': 'Cleaning',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Window cleaning service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Window Cleaning',
        'price': 800,
        'responsibilities': ['Glass cleaning', 'Frame wiping'],
        'status': 'pending',
        'subcategory': 'Window Cleaning',
        'whatsIncluded': ['Cleaner', 'Cloth'],
      },
      {
        'category': 'Electrical',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Circuit breaker installation.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Circuit Breaker Installation',
        'price': 1500,
        'responsibilities': ['Wiring', 'Installation'],
        'status': 'pending',
        'subcategory': 'Circuit Breaker Installation',
        'whatsIncluded': ['Breaker', 'Tools'],
      },
      {
        'category': 'Events & Decor',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[2],
        'description': 'Catering service for events.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Catering Services',
        'price': 5000,
        'responsibilities': ['Food prep', 'Serving'],
        'status': 'pending',
        'subcategory': 'Catering Services',
        'whatsIncluded': ['Food', 'Utensils'],
      },
      {
        'category': 'Home Improvement',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[0],
        'description': 'Interior design consultation.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Interior Design',
        'price': 3000,
        'responsibilities': ['Planning', 'Consultation'],
        'status': 'pending',
        'subcategory': 'Interior Design',
        'whatsIncluded': ['Design plan', 'Suggestions'],
      },
      {
        'category': 'Plumbing',
        'createdAt': getRandomTimestamp(),
        'createdBy': providerIds[1],
        'description': 'Toilet installation service.',
        'images': [
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297399/1000134442_ouxgbf.jpg',
          'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735297404/1000134443_bhnoqd.jpg',
        ],
        'name': 'Toilet Installation',
        'price': 2000,
        'responsibilities': ['Fitting', 'Plumbing'],
        'status': 'pending',
        'subcategory': 'Toilet Installation',
        'whatsIncluded': ['Toilet', 'Fittings'],
      },
    ];

    try {
      for (var service in pendingServices) {
        // Add the pending service and get the document reference
        DocumentReference docRef = await _firestore.collection('pending_services').add(service);
        String serviceId = docRef.id;

        // Update the provider's servicesOffered array
        Object? providerId = service['createdBy'];
        await _firestore.collection('providers').doc(providerId as String?).update({
          'servicesOffered': FieldValue.arrayUnion([serviceId]),
        });

        print('Added pending service $serviceId and updated provider $providerId');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('40 Pending Services added successfully!')),
      );
    } catch (e) {
      print('Error adding pending services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add pending services: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Dummy Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: addDummyUsers,
              child: const Text('Add Dummy Users'),
            ),
            ElevatedButton(
              onPressed: addDummyProviders,
              child: const Text('Add Dummy Providers'),
            ),
            ElevatedButton(
              onPressed: addDummyAdmins,
              child: const Text('Add Dummy Admins'),
            ),
            ElevatedButton(
              onPressed: addDummyPendingServices,
              child: const Text('Add Dummy Pending Services'),
            ),
            ElevatedButton(
              onPressed: addDummyServices,
              child: const Text('Add Dummy Services'),
            ),
            ElevatedButton(
              onPressed: addDummyBookings,
              child: const Text('Add Dummy Bookings'),
            ),
          ],
        ),
      ),
    );
  }
}