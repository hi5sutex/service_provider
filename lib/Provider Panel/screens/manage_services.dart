import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:service_provider/Provider%20Panel/screens/ServiceDetailScreen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      backgroundColor: ProviderTheme.backgroundColor, // Light Gray background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient, // Gradient background
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ProviderTheme.surfaceColor, // White arrow
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Manage Services',
          style: TextStyle(color: ProviderTheme.onPrimaryTextColor), // White text
        ),
        centerTitle: false,
        elevation: 4,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4), // Shadow effect
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ServiceListShimmer();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ProviderTheme.errorTextColor, // Crimson Red for errors
                ),
              ),
            );
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return Center(
              child: Text(
                'No services found.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: ProviderTheme.secondaryTextColor, // Gray text
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
        color: ProviderTheme.surfaceColor, // White card background
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: ProviderTheme.cardHighlightColor, // Light Gray fallback
                      child:  Center(
                        child: FaIcon(
                          FontAwesomeIcons.image,
                          size: 60,
                          color: ProviderTheme.secondaryTextColor, // Gray icon
                        ),
                      ),
                    ),
                  )
                      : Container(
                    height: 180,
                    color: ProviderTheme.cardHighlightColor, // Light Gray fallback
                    child:  Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        size: 60,
                        color: ProviderTheme.secondaryTextColor, // Gray icon
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
                        color: ProviderTheme.primaryColor.withOpacity(0.7), // Dark Navy Blue with opacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${images.length - 1}',
                        style: const TextStyle(
                          color: ProviderTheme.onPrimaryTextColor, // White text
                          fontSize: 12,
                        ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service['price']?.toString() ?? '0'}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ProviderTheme.successColor, // Forest Green for price
                        ),
                      ),
                      Text(
                        service['category'] ?? 'Category',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['subcategory'] ?? 'Subcategory',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: ProviderTheme.secondaryTextColor, // Gray text
                    ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ProviderTheme.secondaryTextColor.withOpacity(0.3), // Slightly darker gray for base
          highlightColor: ProviderTheme.cardHighlightColor, // Light Gray for highlight
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2, // Add subtle elevation for shadow
            shadowColor: ProviderTheme.shadowColor.withOpacity(0.2), // Dark Navy Blue shadow with opacity
            child: Container(
              height: 200,
              color: ProviderTheme.surfaceColor, // White card background
            ),
          ),
        );
      },
    );
  }
}