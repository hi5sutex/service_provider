import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subcategory_wise_services.dart';
import 'package:service_provider/theme.dart';

class SubcategoriesPage extends StatefulWidget {
  final String categoryName;

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
      final docSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryName)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['subcategories'] is List) {
          return List<Map<String, dynamic>>.from(data['subcategories']);
        }
      } else {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      appBar: AppBar(
        // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
        title: const Text(
          'Subcategories',
          style: TextStyle(
            color: ProviderTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
        ),
        // foregroundColor is set by ProviderTheme.appBarTheme.foregroundColor
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subcategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
          }

          final subcategories = snapshot.data ?? [];
          if (subcategories.isEmpty) {
            return Center(
              child: Text(
                'No subcategories found.',
                style: TextStyle(
                  color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenHeight * 0.02,
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
                      builder: (context) => SubcategoryWiseServices(subcategoryName: name),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  elevation: 4.0,
                  color: ProviderTheme.surfaceColor, // Matches #FFFFFF (Surface)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(screenWidth * 0.03),
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
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ProviderTheme.primaryColor, // Matches #060644 (Primary)
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                          child: Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: ProviderTheme.primaryTextColor, // Matches #060644 (Primary Text)
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