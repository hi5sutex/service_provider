import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User Panel/service_details_screen.dart';

class SubcategoryWiseServices extends StatelessWidget {
  final String subcategoryName;

  const SubcategoryWiseServices({
    required this.subcategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subcategoryName),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('subcategory', isEqualTo: subcategoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No services available for this subcategory'));
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  // Navigate to the service details screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(service: service),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Image
                      if (service['images'] != null && (service['images'] as List).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                          child: Image.network(
                            service['images'][0],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Name
                            Text(
                              service['name'] ?? 'Unnamed Service',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            // Service Description
                            Text(
                              service['description'] ?? 'No description available',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 10),
                            // Price
                            Row(
                              children: [
                                Text(
                                  'Price: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${service['price'].toString()}',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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