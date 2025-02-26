import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PendingServiceDetailsScreen extends StatelessWidget {
  final String serviceId;

  const PendingServiceDetailsScreen({required this.serviceId});

  Future<Map<String, dynamic>> _fetchServiceDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('pending_services')
        .doc(serviceId)
        .get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> _updateServiceStatus(String status, Map<String, dynamic> serviceData, BuildContext context) async {
    try {
      if (status == 'Approved') {
        // Move to 'services' collection
        await FirebaseFirestore.instance.collection('services').doc(serviceId).set(serviceData);
        // Remove from 'pending_services'
        await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
      } else if (status == 'Declined') {
        // Move to 'declined_services' collection with a timestamp
        await FirebaseFirestore.instance.collection('declined_services').doc(serviceId).set({
          ...serviceData,
          'status': 'Declined',
          'declinedAt': FieldValue.serverTimestamp(),
        });
        // Remove from 'pending_services'
        await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
      }
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service $status successfully!')),
      );
      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating service status.')),
      );
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Service Details'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchServiceDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading service details.'));
          }

          final service = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceHeader(service),
                  const SizedBox(height: 20),
                  _buildServiceDetailsCard(service),
                  const SizedBox(height: 20),
                  _buildImagesSection(service),
                  const SizedBox(height: 20),
                  _buildActionButtons(service, context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceHeader(Map<String, dynamic> service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service['name'] ?? 'No Name',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          service['description'] ?? 'No Description',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildServiceDetailsCard(Map<String, dynamic> service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Category', service['category'] ?? 'N/A'),
            _buildDetailRow('Subcategory', service['subcategory'] ?? 'N/A'),
            _buildDetailRow('Price', '₹${service['price']?.toString() ?? 'N/A'}'),
            _buildDetailRow(
              'Created At',
              service['createdAt']?.toDate()?.toString() ?? 'N/A',
            ),
            _buildDetailRow('Created By', service['createdBy'] ?? 'N/A'),
            _buildDetailRow('Status', service['status'] ?? 'N/A'),
            const SizedBox(height: 16),
            _buildListSection('What\'s Included', service['whatsIncluded']),
            const SizedBox(height: 16),
            _buildListSection('Responsibilities', service['responsibilities']),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(Map<String, dynamic> service) {
    final images = service['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> service, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => _updateServiceStatus('Approved', service, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Accept'),
        ),
        ElevatedButton(
          onPressed: () => _updateServiceStatus('Declined', service, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Decline'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text('• $item', style: const TextStyle(fontSize: 14)),
        )),
      ],
    );
  }
}