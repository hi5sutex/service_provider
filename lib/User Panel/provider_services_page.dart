import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/service_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

class ProviderServicesPage extends StatefulWidget {
  final String providerId;

  const ProviderServicesPage({required this.providerId, Key? key}) : super(key: key);

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  Future<List<Map<String, dynamic>>> fetchServices() async {
    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
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
        backgroundColor: UserTheme.primaryColor,
        title: Text('Provider Services', style: TextStyle(color: UserTheme.onPrimaryTextColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: UserTheme.onPrimaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return Center(
              child: Text(
                'No services found.',
                style: TextStyle(fontSize: 16, color: UserTheme.secondaryTextColor),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceItem(service, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service, BuildContext context) {
    final images = service['images'] ?? [];
    final displayImage = images.isNotEmpty ? images[0] : null;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceId: service['id']),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: displayImage != null
                      ? Image.network(
                    displayImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: UserTheme.dividerColor,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: UserTheme.secondaryTextColor,
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 180,
                    color: UserTheme.dividerColor,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: UserTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${images.length - 1}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? 'Service Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: UserTheme.primaryTextColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${service['price'] ?? '0'}/hr',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: UserTheme.primaryColor,
                        ),
                      ),
                      Text(
                        service['category'] ?? 'Category',
                        style: TextStyle(
                          fontSize: 14,
                          color: UserTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  if (service['subcategory'] != null)
                    Text(
                      service['subcategory'],
                      style: TextStyle(fontSize: 14, color: UserTheme.secondaryTextColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.only(bottom: 16),
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