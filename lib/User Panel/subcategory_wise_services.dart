import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/service_details_screen.dart';
import 'package:service_provider/theme.dart';

class SubcategoryWiseServices extends StatelessWidget {
  final String subcategoryName;

  const SubcategoryWiseServices({
    required this.subcategoryName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.secondaryColorCustom, // White background
      appBar: AppBar(
        title: Text(
          subcategoryName,
          style: TextStyle(color: AppTheme.secondaryColorCustom), // White text
        ),
        backgroundColor: AppTheme.primaryColorCustom, // Dark blue
        foregroundColor: AppTheme.secondaryColorCustom, // White icons
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('subcategory', isEqualTo: subcategoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryColorCustom));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No services available for this subcategory',
                    style: TextStyle(color: Colors.black)));
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final serviceDoc = services[index];
              final service = serviceDoc.data() as Map<String, dynamic>;
              final serviceId = serviceDoc.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        serviceId: serviceId,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(screenWidth * 0.025),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  color: AppTheme.secondaryColorCustom, // White card background
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Image
                      if (service['images'] != null && (service['images'] as List).isNotEmpty)
                        ClipRRect(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(screenWidth * 0.025)),
                          child: Image.network(
                            service['images'][0],
                            height: screenHeight * 0.25,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: screenHeight * 0.25,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: screenWidth * 0.125, color: Colors.grey[500]),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.025),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Name
                            Text(
                              service['name'] ?? 'Unnamed Service',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // Service Description
                            Text(
                              service['description'] ?? 'No description available',
                              style: TextStyle(
                                  fontSize: screenWidth * 0.035, color: Colors.grey[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            // Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Price: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '₹${service['price'].toString()}',
                                      style: TextStyle(
                                        color: AppTheme.providerGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
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