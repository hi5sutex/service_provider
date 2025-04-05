import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingServiceDetailsScreen extends StatelessWidget {
  final String serviceId;

  const PendingServiceDetailsScreen({Key? key, required this.serviceId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchServiceDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('pending_services')
        .doc(serviceId)
        .get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> _updateServiceStatus(String status, Map<String, dynamic> serviceData, BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

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

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service $status successfully!'),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('Error: $e');
    }
  }

  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> service, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateServiceStatus(
                  action == 'approve' ? 'Approved' : 'Declined',
                  service,
                  context
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'approve' ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Review'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a pending service awaiting approval'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchServiceDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading service details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final service = snapshot.data!;
          return _buildBody(context, service);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> service) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.amber.shade100,
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Pending Review',
                style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${serviceId.substring(0, 6)}...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: isTablet
              ? _buildTabletLayout(context, service)
              : _buildMobileLayout(context, service),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showConfirmationDialog(context, service, 'decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showConfirmationDialog(context, service, 'approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, Map<String, dynamic> service) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Images
        Expanded(
          flex: 2,
          child: _buildImagesSection(service),
        ),

        // Right column - Details
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceHeader(service),
                const SizedBox(height: 24),
                _buildServiceDetailsCard(service),
                const SizedBox(height: 24),
                _buildProviderInfo(service),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> service) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagesSection(service),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceHeader(service),
                const SizedBox(height: 24),
                _buildServiceDetailsCard(service),
                const SizedBox(height: 24),
                _buildProviderInfo(service),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHeader(Map<String, dynamic> service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                service['category'] ?? 'No Category',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                service['subcategory'] ?? 'No Subcategory',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          service['name'] ?? 'No Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${service['price']?.toString() ?? 'N/A'}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          service['description'] ?? 'No Description',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetailsCard(Map<String, dynamic> service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('What\'s Included'),
        const SizedBox(height: 12),
        _buildList(service['whatsIncluded']),
        const SizedBox(height: 24),

        _buildSectionTitle('Provider Responsibilities'),
        const SizedBox(height: 12),
        _buildList(service['responsibilities']),
      ],
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic> service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Submission Details'),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person_outline,
              title: 'Submitted by',
              value: service['createdBy'] ?? 'Unknown',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: 'Submitted on',
              value: _formatDate(service['createdAt']),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.update,
              title: 'Status',
              value: service['status'] ?? 'Pending',
              valueColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildList(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return const Text(
        'No items specified',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Column(
      children: items.map((item) => _buildListItem(item)).toList(),
    );
  }

  Widget _buildListItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagesSection(Map<String, dynamic> service) {
    final images = service['images'] as List<dynamic>? ?? [];

    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No images available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Image counter
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${index + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}