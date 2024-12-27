import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// First update the Service model to include serviceName
class Service {
  final String id;
  final String serviceName;  // Changed from title
  final String category;
  final double price;
  final String imageUrl;

  Service({
    required this.id,
    required this.serviceName,  // Changed from title
    required this.category,
    required this.price,
    required this.imageUrl,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      serviceName: data['name'] ?? '',  // Changed from title
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
          ? data['images'][0]
          : '',
    );
  }
}

class ServiceDetailsPage extends StatelessWidget {
  final String category;

  const ServiceDetailsPage({required this.category});

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
                    service.serviceName,  // Using serviceName instead of category
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '\$${service.price}/hr',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    // Handle service selection
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}