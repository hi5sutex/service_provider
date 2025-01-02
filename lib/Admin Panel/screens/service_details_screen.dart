import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? providerData;

  @override
  void initState() {
    super.initState();
    _fetchServiceAndProviderDetails();
  }

  Future<void> _fetchServiceAndProviderDetails() async {
    try {
      // Fetch service details
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        serviceData = serviceSnapshot.data() as Map<String, dynamic>;
        String providerId = serviceData!['createdBy'];

        // Fetch provider details
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceData?['name'] ?? 'Service Details'),
      ),
      body: serviceData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Details
              Text(
                serviceData!['name'] ?? 'No Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                serviceData!['description'] ?? 'No Description',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Category: ${serviceData!['category'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Subcategory: ${serviceData!['subcategory'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Price: ₹${serviceData!['price']?.toString()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Images
              if ((serviceData!['images'] as List<dynamic>?)?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.from(
                      (serviceData!['images'] as List<dynamic>).map(
                            (image) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(image),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // What's Included
              if ((serviceData!['whatsIncluded'] as List<dynamic>?)?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What\'s Included:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.from(
                      (serviceData!['whatsIncluded'] as List<dynamic>).map(
                            (item) => Text('- $item'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // Responsibilities
              if ((serviceData!['responsibilities'] as List<dynamic>?)?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Responsibilities:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.from(
                      (serviceData!['responsibilities'] as List<dynamic>).map(
                            (item) => Text('- $item'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                'Created At: ${serviceData!['createdAt']?.toDate()?.toString() ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              // Provider Details
              if (providerData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provided By:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Name: ${providerData!['name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Contact: ${providerData!['phone'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Email: ${providerData!['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Address: ${providerData!['address']['string'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
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
