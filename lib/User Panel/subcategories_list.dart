import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/subcategory_wise_services.dart';

class SubcategoriesPage extends StatefulWidget {
  final String categoryName;

  const SubcategoriesPage({
    required this.categoryName,
  });

  @override
  State<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends State<SubcategoriesPage> {
  late Future<List<String>> _subcategoriesFuture;
  final Map<String, Image> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _subcategoriesFuture = _fetchSubcategories();
  }

  Future<List<String>> _fetchSubcategories() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('name', isEqualTo: widget.categoryName)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    final doc = querySnapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    final subcategories = List<String>.from(data['subcategories'] ?? []);

    // Preload images
    for (final subcategory in subcategories) {
      final imagePath =
          "android/assets/categories_images/${widget.categoryName}/$subcategory.png";
      _imageCache[subcategory] = Image.asset(imagePath, fit: BoxFit.cover);
    }

    return subcategories;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure preloaded images are resolved in the widget tree
    for (final image in _imageCache.values) {
      precacheImage(image.image, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Add search functionality if needed
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _subcategoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final subcategories = snapshot.data ?? [];

          if (subcategories.isEmpty) {
            return Center(child: Text('No subcategories available'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1,
            ),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategories[index];
              final image = _imageCache[subcategory];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubcategoryWiseServices(
                        subcategoryName: subcategory,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image section with rounded corners
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                          child: image ??
                              Image.asset(
                                'android/assets/categories_images/placeholder.png',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                      // Subcategory name section
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Center(
                            child: Text(
                              subcategory,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
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
