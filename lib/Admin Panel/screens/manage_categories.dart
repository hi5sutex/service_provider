import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin Panel/screens/Editcategories.dart';
import 'package:service_provider/Admin Panel/screens/EditSubcategories.dart';

class ManageCategoriesScreen extends StatefulWidget {
  @override
  _ManageCategoriesScreenState createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> expandedCategories = {};
  Map<String, List<QueryDocumentSnapshot>> subcategoriesCache = {};
  List<QueryDocumentSnapshot> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      setState(() {
        categories = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching categories: $e')),
      );
    }
  }

  Future<void> _fetchSubcategories(String categoryId) async {
    if (!subcategoriesCache.containsKey(categoryId)) {
      try {
        final snapshot = await _firestore
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .get();
        setState(() {
          subcategoriesCache[categoryId] = snapshot.docs;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching subcategories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Add category logic
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories..',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                ? const Center(child: Text('No categories found.'))
                : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isExpanded = expandedCategories[category.id] ?? false;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: InkWell(
                          onTap: () async {
                            await _fetchSubcategories(category.id);
                            setState(() {
                              expandedCategories[category.id] = !isExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                category['name'] ?? 'No Name',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 300),
                                turns: isExpanded ? 0.25 : 0,
                                child: const Icon(Icons.arrow_forward_ios, size: 14),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditCategoriesPage(
                                      categoryId: category.id,
                                      categoryName: category['name'] ?? 'No Name',
                                      imageUrl: category['imageUrl'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                // Delete category logic
                              },
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: isExpanded
                            ? ((subcategoriesCache[category.id]?.length ?? 0) * 56.0)
                            : 0,
                        curve: Curves.easeInOut,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              if (subcategoriesCache.containsKey(category.id))
                                ...subcategoriesCache[category.id]!.map((subcategory) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: ListTile(
                                      title: Text(
                                        subcategory['name'] ?? 'No Name',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditSubcategoriesPage(
                                                categoryId: category.id,
                                                subcategoryId: subcategory.id,
                                                subcategoryName:
                                                subcategory['name'] ?? 'No Name',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
