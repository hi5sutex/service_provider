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
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      appBar: AppBar(
        // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
        title: Text(
          subcategoryName,
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
        // foregroundColor is set by ProviderTheme.appBarTheme.foregroundColor
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('subcategory', isEqualTo: subcategoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No services available for this subcategory',
                style: TextStyle(
                  color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
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
                  color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
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
                              color: ProviderTheme.dividerColor, // Matches #D1D9E1 (Divider)
                              child: Icon(
                                Icons.image,
                                size: screenWidth * 0.125,
                                color: ProviderTheme.disabledTextColor, // Matches #B0B8C4 (Disabled Text)
                              ),
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
                                color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // Service Description
                            Text(
                              service['description'] ?? 'No description available',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: ProviderTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                              ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                                      ),
                                    ),
                                    Text(
                                      '₹${service['price'].toString()}',
                                      style: TextStyle(
                                        color: ProviderTheme.successColor, // Matches #388E3C (Success Text)
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: screenWidth * 0.04,
                                  color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
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