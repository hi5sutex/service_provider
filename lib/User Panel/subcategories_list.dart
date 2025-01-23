import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subcategory_wise_services.dart';

class SubcategoriesPage extends StatefulWidget {
  final String categoryName; // Pass the Firestore document ID of the category

  const SubcategoriesPage({required this.categoryName});

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  late Future<List<Map<String, dynamic>>> _subcategoriesFuture;

  @override
  void initState() {
    super.initState();
    _subcategoriesFuture = _fetchSubcategories();
  }

  Future<List<Map<String, dynamic>>> _fetchSubcategories() async {
    try {
      // Attempt to fetch the document based on the category name as ID
      final docSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryName) // Assuming categoryName is the document ID
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['subcategories'] is List) {
          return List<Map<String, dynamic>>.from(data['subcategories']);
        }
      } else {
        // If categoryName is not the document ID, query based on the name field
        final querySnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: widget.categoryName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          if (data != null && data['subcategories'] is List) {
            return List<Map<String, dynamic>>.from(data['subcategories']);
          }
        }
      }

      return [];
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subcategories'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subcategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final subcategories = snapshot.data ?? [];
          if (subcategories.isEmpty) {
            return const Center(child: Text('No subcategories found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategories[index];
              final name = subcategory['name'] ?? 'Unknown';
              final imageUrl = subcategory['imageUrl'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SubcategoryWiseServices(subcategoryName: name),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/placeholder.png',
                                fit: BoxFit.cover,
                              );
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Center(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
