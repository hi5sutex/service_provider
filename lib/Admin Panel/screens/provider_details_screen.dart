import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Admin%20Panel/screens/booking_details_screen.dart';
import 'package:service_provider/Admin Panel/screens/service_details_screen.dart'; // Add the service details screen import

class ProviderDetailsScreen extends StatelessWidget {
  final String providerId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProviderDetailsScreen({Key? key, required this.providerId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchProviderDetails() async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance.collection('providers').doc(providerId).get();
    return providerDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchProviderServices() async {
    QuerySnapshot servicesSnapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('createdBy', isEqualTo: providerId)
        .get();

    return servicesSnapshot.docs.map((doc) {
      // Extract document ID and include it in the map
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID
      return data;
    }).toList();
  }


  Future<List<Map<String, dynamic>>> _fetchProviderBookings() async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .get();

    List<Map<String, dynamic>> bookings = bookingsSnapshot.docs.map((doc) {
      Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;
      booking['id'] = doc.id; // Add booking ID
      return booking;
    }).toList();

    // Fetch user details and service details in parallel
    await Future.wait(bookings.map((booking) async {
      if (booking['userId'] != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking['userId'])
            .get();
        if (userDoc.exists) {
          booking['userName'] = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown User';
        }
      }

      if (booking['serviceId'] != null) {
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(booking['serviceId'])
            .get();
        if (serviceDoc.exists) {
          booking['serviceName'] = (serviceDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Service';
        }
      }

      // Format booking date safely
      if (booking['bookingDate'] is Timestamp) {
        booking['bookingDate'] = DateFormat('dd/MM/yyyy kk:mm').format((booking['bookingDate'] as Timestamp).toDate());
      }
    }));

    return bookings;
  }

  Future<List<Map<String, dynamic>>> _fetchProviderPayments() async {
    QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('providerId', isEqualTo: providerId)
        .get();
    return paymentsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Provider'),
          content: Text('Are you sure you want to delete this provider?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('providers').doc(providerId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Provider deleted successfully!')),
                );
                Navigator.of(context).pop(); // Close the screen
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _isAdmin() {
    final currentUser = _auth.currentUser;
    return currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProviderDetails(),
        builder: (context, providerSnapshot) {
          if (providerSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (providerSnapshot.hasError || !providerSnapshot.hasData) {
            return Center(child: Text('Error loading provider details.'));
          }

          final provider = providerSnapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    provider['profileImage'] ?? 'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
                  ),
                  backgroundColor: Colors.blueGrey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  provider['name'] ?? 'N/A',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(provider['email'] ?? 'N/A', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(provider['phone'] ?? 'N/A', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  provider['createdAt'] != null
                      ? DateFormat('dd/MM/yyyy  kk:mm').format((provider['createdAt'] as Timestamp).toDate()) // Format the Timestamp
                      : 'N/A',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),
              _isAdmin()
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Implement edit functionality here
                    },
                    child: Text('Edit Provider'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    child: Text('Delete Provider'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
                  : SizedBox(),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProviderServices(),
                builder: (context, servicesSnapshot) {
                  if (servicesSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (servicesSnapshot.hasError || !servicesSnapshot.hasData) {
                    return Text('No services found.');
                  }
                  final services = servicesSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services (${services.length}):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...services.map((service) {
                        return GestureDetector(
                          onTap: () {
                            print(service['id']);
                            Navigator.of(context).push(MaterialPageRoute(

                              builder: (context) => ServiceDetailsScreen(serviceId:  service['id']), // Navigate to service details screen
                            ));
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(service['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${service['category']}'),
                                  SizedBox(height: 4),
                                  Text('Description: ${service['description']}'),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward), // Trailing icon for navigation
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProviderBookings(),
                builder: (context, bookingSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (bookingSnapshot.hasError || !bookingSnapshot.hasData) {
                    return Text('No bookings found.');
                  }
                  final bookings = bookingSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings (${bookings.length}):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...bookings.map((booking) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Service: ${booking['serviceName']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User: ${booking['userName']}'),
                                Text('Status: ${booking['status']}'),
                                SizedBox(height: 4),
                                Text('Booking Date: ${booking['bookingDate']}'),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(bookingData: booking),
                              ));
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchProviderPayments(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (paymentSnapshot.hasError || !paymentSnapshot.hasData) {
                    return Text('No payments found.');
                  }
                  final payments = paymentSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments (${payments.length}):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...payments.map((payment) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Amount: ${payment['paymentAmount']}'),
                            subtitle: Text('Date: ${payment['paymentDate']}'),
                            trailing: Icon(Icons.receipt),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
