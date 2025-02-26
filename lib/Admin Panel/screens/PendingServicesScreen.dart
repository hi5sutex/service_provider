import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/pending_service_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class PendingServicesScreen extends StatefulWidget {
  @override
  _PendingServicesScreenState createState() => _PendingServicesScreenState();
}

class _PendingServicesScreenState extends State<PendingServicesScreen> {
  Future<List<Map<String, dynamic>>> _fetchPendingServices() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('pending_services')
        .where('status', isEqualTo: 'pending')
        .get();

    List<Map<String, dynamic>> services = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    print("Fetched Pending Services: $services"); // Debugging line
    return services;
  }

  void _updateServiceStatus(String serviceId, String status, Map<String, dynamic> serviceData) async {
    if (status == 'Approved') {
      await FirebaseFirestore.instance.collection('services').doc(serviceId).set(serviceData);
      await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
    } else if (status == 'Declined') {
      await FirebaseFirestore.instance.collection('declined_services').doc(serviceId).set({
        ...serviceData,
        'status': 'Declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
    }
    setState(() {}); // Refresh UI after update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Services'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPendingServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading pending services.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending services found.'));
          }

          final services = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service['name'] ?? 'N/A',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${service['category'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Subcategory: ${service['subcategory'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Price: ₹${service['price']?.toString() ?? 'N/A'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PendingServiceDetailsScreen(serviceId: service['id']),
                      ),
                    );
                  },
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _updateServiceStatus(service['id'], 'Approved', service),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _updateServiceStatus(service['id'], 'Declined', service),
                  tooltip: 'Decline',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5, // Show 5 shimmer cards
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 18, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 100, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 120, height: 14, color: Colors.white),
              const SizedBox(height: 4),
              Container(width: 80, height: 14, color: Colors.white),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100, height: 36, color: Colors.white),
                  Row(
                    children: [
                      Container(width: 80, height: 36, color: Colors.white),
                      const SizedBox(width: 8),
                      Container(width: 80, height: 36, color: Colors.white),
                    ],
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

