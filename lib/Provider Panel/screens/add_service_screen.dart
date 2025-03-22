import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:service_provider/notification_service.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _whatsIncludedController;
  late final TextEditingController _responsibilitiesController;

  String? selectedCategory;
  String? selectedSubcategory;
  List<String> subcategories = [];
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  List<String> whatsIncludedList = [];
  List<String> responsibilitiesList = [];
  List<String> categories = [];

  // Define colors
  static const Color primaryColor = Color(0xFF060644);
  static const Color secondaryColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _whatsIncludedController = TextEditingController();
    _responsibilitiesController = TextEditingController();
    fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _whatsIncludedController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (mounted) {
        setState(() {
          categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load categories')),
        );
      }
    }
  }

  Future<void> fetchSubcategories(String categoryName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (mounted) {
        setState(() {
          if (snapshot.docs.isNotEmpty) {
            subcategories = (snapshot.docs.first['subcategories'] as List)
                .map<String>((subcategory) => subcategory['name'] as String)
                .toList();
          } else {
            subcategories = [];
          }
          selectedSubcategory = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      if (mounted) {
        setState(() {
          subcategories = [];
          selectedSubcategory = null;
        });
      }
    }
  }

  Future<void> selectImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1000);
      if (pickedFiles != null) {
        final newImages = pickedFiles.map((e) => File(e.path)).toList();
        if (selectedImages.length + newImages.length <= 5) {
          setState(() {
            selectedImages.addAll(newImages);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick images')),
      );
    }
  }

  Future<List<String>> uploadImagesToCloudinary() async {
    List<String> imageUrls = [];
    const String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dpcjw0g5c/image/upload';
    const String uploadPreset = 'flutter_unsigned_upload';

    for (var image in selectedImages) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseBody);
          final secureUrl = jsonResponse['secure_url'] as String?;
          if (secureUrl != null) {
            imageUrls.add(secureUrl);
          }
        } else {
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
      }
    }
    return imageUrls;
  }

  Future<String?> _getAdminUid() async {
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .limit(1) // Assuming one admin for simplicity
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        return adminSnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching admin UID: $e');
      return null;
    }
  }

  Future<void> submitService() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null || selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final providerId = FirebaseAuth.instance.currentUser?.uid;
      if (providerId == null) {
        throw Exception('User not authenticated');
      }

      final imageUrls = await uploadImagesToCloudinary();
      if (imageUrls.isEmpty && selectedImages.isNotEmpty) {
        throw Exception('Image upload failed');
      }

      DocumentReference serviceRef = await FirebaseFirestore.instance.collection('pending_services').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': selectedCategory,
        'subcategory': selectedSubcategory,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'whatsIncluded': whatsIncludedList,
        'responsibilities': responsibilitiesList,
        'images': imageUrls,
        'createdBy': providerId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      String? adminUid = await _getAdminUid();
      if (adminUid != null) {
        // Send notification to admin
        await NotificationService().sendNotification(
          toUserId: adminUid,
          toRole: 'admin',
          title: 'New Service Request',
          body: 'A new service "${_nameController.text.trim()}" has been submitted by provider $providerId for approval.',
          type: 'service_request',
          data: {
            'serviceId': serviceRef.id,
          },
        );
      } else {
        debugPrint('No admin found to notify');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service submitted for approval')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit service')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Helper method for section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced dynamic list widget
  Widget _buildDynamicList(
      String label, String hint, List<String> itemsList, TextEditingController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itemsList
                  .map(
                    (item) => Chip(
                  label: Text(item, style: const TextStyle(color: secondaryColor)),
                  backgroundColor: primaryColor,
                  deleteIcon: const Icon(Icons.close, color: secondaryColor),
                  onDeleted: () => setState(() => itemsList.remove(item)),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: primaryColor),
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty && !itemsList.contains(text)) {
                      setState(() {
                        itemsList.add(text);
                        controller.clear(); // Clear input after adding
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Add New Service', style: TextStyle(color: secondaryColor)),
        elevation: 0,
        iconTheme: const IconThemeData(color: secondaryColor),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Details Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Service Details', Icons.build),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Service Name',
                              hintText: 'e.g., Home Cleaning, AC Repair',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Please enter a service name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'e.g., Includes dusting, mopping, sanitization',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            maxLines: 3,
                            validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Please enter a description' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              hintText: 'Enter service price',
                              prefixText: '\$ ', // Currency prefix for professionalism
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) return 'Please enter a price';
                              if (double.tryParse(value!) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category & Subcategory Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Category & Subcategory', Icons.category),
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: categories
                                .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                                selectedSubcategory = null;
                                fetchSubcategories(value!);
                              });
                            },
                            validator: (value) => value == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedSubcategory,
                            decoration: InputDecoration(
                              labelText: 'Subcategory',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: subcategories
                                .map((subcategory) => DropdownMenuItem(
                              value: subcategory,
                              child: Text(subcategory),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => selectedSubcategory = value),
                            validator: (value) => value == null ? 'Please select a subcategory' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // What's Included Section
                  _buildDynamicList(
                    'What\'s Included',
                    'e.g., Free consultation, Cleaning tools',
                    whatsIncludedList,
                    _whatsIncludedController,
                  ),
                  const SizedBox(height: 20),

                  // Responsibilities Section
                  _buildDynamicList(
                    'Responsibilities',
                    'e.g., Arrive on time, Complete tasks',
                    responsibilitiesList,
                    _responsibilitiesController,
                  ),
                  const SizedBox(height: 20),

                  // Images Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Images', Icons.image),
                          Text(
                            '${selectedImages.length}/5 images selected',
                            style: const TextStyle(color: primaryColor),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedImages
                                .map(
                                  (image) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      image,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => selectedImages.remove(image)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: secondaryColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: selectImages,
                            icon: const Icon(Icons.add_photo_alternate, size: 20),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: secondaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submission Note
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Your service will be reviewed by our team before being published.',
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitService,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: secondaryColor)
                          : const Text('Submit Service', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20), // Extra space at the bottom
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }
}