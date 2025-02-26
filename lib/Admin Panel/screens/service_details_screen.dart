import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? providerData;
  int? totalBookings;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchServiceAndProviderDetails();
    _fetchTotalBookings();
  }

  /// Fetches service and provider details from Firestore
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
      } else {
        print('Service not found.');
      }
    } catch (e) {
      print('Error fetching service or provider details: $e');
    }
  }

  /// Fetches the total number of bookings for this service from Firestore
  Future<void> _fetchTotalBookings() async {
    try {
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceId', isEqualTo: widget.serviceId)
          .get();

      setState(() {
        totalBookings = bookingsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching total bookings: $e');
    }
  }

  /// Blocks the service by updating its status in Firestore
  Future<void> _blockService() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({'isBlocked': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service blocked successfully!')),
      );
    } catch (e) {
      print('Error blocking service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to block service.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceData?['name'] ?? 'Service Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: _blockService,
            tooltip: 'Block Service',
          ),
        ],
      ),
      body: serviceData == null
          ? _buildShimmerEffect()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceHeader(),
              const SizedBox(height: 20),
              _buildServiceDetailsCard(),
              const SizedBox(height: 20),
              _buildImagesSection(),
              const SizedBox(height: 20),
              _buildTotalBookingsCard(),
              const SizedBox(height: 20),
              if (providerData != null) _buildProviderDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the service header with name and description
  Widget _buildServiceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          serviceData!['name'] ?? 'No Name',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          serviceData!['description'] ?? 'No Description',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  /// Builds the service details card
  Widget _buildServiceDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Category', serviceData!['category'] ?? 'N/A'),
            _buildDetailRow('Subcategory', serviceData!['subcategory'] ?? 'N/A'),
            _buildDetailRow('Price', '₹${serviceData!['price']?.toString() ?? 'N/A'}'),
            _buildDetailRow(
              'Created At',
              serviceData!['createdAt']?.toDate()?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _buildListSection('What\'s Included', serviceData!['whatsIncluded']),
            const SizedBox(height: 16),
            _buildListSection('Responsibilities', serviceData!['responsibilities']),
          ],
        ),
      ),
    );
  }

  /// Builds the images section
  Widget _buildImagesSection() {
    final images = serviceData!['images'] as List<dynamic>?;
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
            Stack(
              children: [
                // PageView for the image slider
                SizedBox(
                  height: 250, // Increased height for better visibility
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index; // Update current page index
                      });
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover, // Ensures image fills the space
                        ),
                      );
                    },
                  ),
                ),
                // Indicators (dots) at the bottom
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index ? Colors.blue : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// Builds the total bookings card
  Widget _buildTotalBookingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Bookings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              totalBookings?.toString() ?? 'Loading...',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the provider details card
  Widget _buildProviderDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provided By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Name', providerData!['name'] ?? 'N/A'),
            _buildDetailRow('Contact', providerData!['phone'] ?? 'N/A'),
            _buildDetailRow('Email', providerData!['email'] ?? 'N/A'),
            _buildDetailRow('Address', providerData!['address']['string'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  /// Helper widget for displaying key-value pairs
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

  /// Helper widget for displaying list sections
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

  /// Builds the shimmer effect for loading state
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200, height: 28, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 16, color: Colors.white),
            const SizedBox(height: 20),
            Container(width: 150, height: 16, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 100, height: 16, color: Colors.white),
            const SizedBox(height: 20),
            Container(width: 80, height: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}