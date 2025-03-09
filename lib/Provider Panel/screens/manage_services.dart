import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Provider%20Panel/screens/ServiceDetailScreen.dart';
import 'package:shimmer/shimmer.dart';

class ManageServices extends StatefulWidget {
  const ManageServices({Key? key}) : super(key: key);

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {
  late final String providerId;

  @override
  void initState() {
    super.initState();
    providerId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<List<Map<String, dynamic>>> fetchServices() async {
    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();

      if (!providerDoc.exists) return [];

      List<dynamic> serviceIds = providerDoc.data()?['servicesOffered'] ?? [];
      List<Map<String, dynamic>> services = [];

      for (String serviceId in serviceIds) {
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get();

        if (serviceDoc.exists) {
          Map<String, dynamic> serviceData = serviceDoc.data() as Map<String, dynamic>;
          serviceData['id'] = serviceDoc.id;
          services.add(serviceData);
        }
      }
      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF060644),
        title: const Text('Manage Services', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ServiceListShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(
              child: Text(
                'No services found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceItem(service: service);
            },
          );
        },
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceItem({required this.service, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final images = service['images'] ?? [];
    final displayImage = images.isNotEmpty ? images[0] : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(serviceId: service['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: displayImage != null
                      ? Image.network(
                    displayImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${images.length - 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? 'Service Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF060644),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service['price'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        service['category'] ?? 'Category',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF060644),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['subcategory'] ?? 'Subcategory',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceListShimmer extends StatelessWidget {
  const ServiceListShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 200,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}