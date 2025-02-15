import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Move to 'services' collection
      await FirebaseFirestore.instance.collection('services').doc(serviceId).set(serviceData);
      // Remove from pending_services
      await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
    } else if (status == 'Declined') {
      // Move to 'declined_services' collection
      await FirebaseFirestore.instance.collection('declined_services').doc(serviceId).set({
        ...serviceData,
        'status': 'Declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      // Remove from pending_services
      await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
    }
    setState(() {}); // Refresh UI after update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pending Services')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPendingServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading pending services.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No pending services found.'));
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 4),
            Text(
              service['category'] ?? 'N/A',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Price: ₹${service['price']?.toString() ?? 'N/A'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _updateServiceStatus(service['id'], 'Approved', service),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Approve'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _updateServiceStatus(service['id'], 'Declined', service),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
