import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/service_details.dart';

// Service model to include service details
class Service {
  final String id;
  final String serviceName;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final List<String> responsibilities;
  final List<String> whatsIncluded;

  Service({
    required this.id,
    required this.serviceName,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.responsibilities,
    required this.whatsIncluded,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      serviceName: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
          ? data['images'][0]
          : '',
      description: data['description'] ?? '',
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      whatsIncluded: List<String>.from(data['whatsIncluded'] ?? []),
    );
  }
}

class ServiceListPage extends StatelessWidget {
  final String category;

  const ServiceListPage({required this.category});

  Stream<List<Service>> getServicesByCategory() {
    return FirebaseFirestore.instance
        .collection('services')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<List<Service>>(
        stream: getServicesByCategory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text('No services found for $category'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Service service = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: service.imageUrl.isNotEmpty
                        ? Image.network(
                      service.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.error),
                        );
                      },
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(Icons.image),
                    ),
                  ),
                  title: Text(
                    service.serviceName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '\$${service.price.toStringAsFixed(2)}/hr',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedServicePage(
                            serviceName: service.serviceName,
                            category: service.category,
                            price: service.price,
                            description: service.description,
                            responsibilities: service.responsibilities,
                            subcategory: service.category,
                            whatsIncluded: service.whatsIncluded,
                            images: [service.imageUrl],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text('View in Detail'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
