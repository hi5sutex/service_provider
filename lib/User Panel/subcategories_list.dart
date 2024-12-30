import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider%20Panel/screens/manage_services.dart';
import 'package:service_provider/User%20Panel/subcategory_wise_services.dart';

class SubcategoriesPage extends StatelessWidget {
  final String categoryName;

  const SubcategoriesPage({
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName), // Set the screen title to the category name
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available for this category'));
          }

          final doc = snapshot.data!.docs.first; // Assume name is unique
          final data = doc.data() as Map<String, dynamic>;
          final subcategories = data['subcategories'] as List<dynamic>? ?? [];

          if (subcategories.isEmpty) {
            return Center(child: Text('No subcategories available'));
          }

          return ListView.builder(
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategories[index];
              return ListTile(
                title: Text(subcategory),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to the service details screen for now
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubcategoryWiseServices(
                        subcategoryName: subcategory,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
