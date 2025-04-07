import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
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

  // Focus nodes for auto-navigation
  late final FocusNode _nameFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _priceFocusNode;
  late final FocusNode _whatsIncludedFocusNode;
  late final FocusNode _responsibilitiesFocusNode;

  String? selectedCategory;
  String? selectedSubcategory;
  List<String> subcategories = [];
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  List<String> whatsIncludedList = [];
  List<String> responsibilitiesList = [];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _whatsIncludedController = TextEditingController();
    _responsibilitiesController = TextEditingController();

    // Initialize focus nodes
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _priceFocusNode = FocusNode();
    _whatsIncludedFocusNode = FocusNode();
    _responsibilitiesFocusNode = FocusNode();

    fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _whatsIncludedController.dispose();
    _responsibilitiesController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    _whatsIncludedFocusNode.dispose();
    _responsibilitiesFocusNode.dispose();

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
        SnackBar(
          content: Text(
            'Fill all the details plz.',
          ),
        ),
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

        // Show custom SnackBar to provider
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Service "${_nameController.text.trim()}" submitted successfully! Awaiting admin approval.',
              ),
            ),
          );
        }
      } else {
        debugPrint('No admin found to notify');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit service'),
            backgroundColor: ProviderTheme.errorTextColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          FaIcon(icon, color: ProviderTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ProviderTheme.primaryTextColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced dynamic list widget
  Widget _buildDynamicList(
      String label, String hint, List<String> itemsList, TextEditingController controller, FocusNode focusNode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ProviderTheme.primaryTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: itemsList
                  .map(
                    (item) => Chip(
                  label: Text(
                    item,
                    style: const TextStyle(color: ProviderTheme.onPrimaryTextColor),
                  ),
                  backgroundColor: ProviderTheme.secondaryColor.withAlpha(200),
                  deleteIcon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: ProviderTheme.onPrimaryTextColor,
                    size: 16,
                  ),
                  onDeleted: () => setState(() => itemsList.remove(item)),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: ProviderTheme.disabledTextColor),
                filled: true,
                fillColor: ProviderTheme.cardHighlightColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.plus,
                    color: ProviderTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty && !itemsList.contains(text)) {
                      setState(() {
                        itemsList.add(text);
                        controller.clear();
                      });
                    }
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                final text = value.trim();
                if (text.isNotEmpty && !itemsList.contains(text)) {
                  setState(() {
                    itemsList.add(text);
                    controller.clear();
                  });
                }
                if (controller == _whatsIncludedController) {
                  FocusScope.of(context).requestFocus(_responsibilitiesFocusNode);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ProviderTheme.themeData,
      home: Scaffold(
        backgroundColor: ProviderTheme.backgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ProviderTheme.primaryGradient,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: ProviderTheme.surfaceColor,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context); // Navigate back when pressed
              },
            ),
          ),
          title: const Text('Add New Service'),
          centerTitle: false,
          elevation: 4,
          shadowColor: ProviderTheme.shadowColor.withOpacity(0.4),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Service Details', FontAwesomeIcons.screwdriverWrench),
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Service Name',
                                hintText: 'e.g., Home Cleaning, AC Repair',
                              ),
                              validator: (value) =>
                              value?.trim().isEmpty ?? true ? 'Please enter a service name' : null,
                              onFieldSubmitted: (value) {
                                FocusScope.of(context).requestFocus(_descriptionFocusNode);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              focusNode: _descriptionFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'e.g., Includes dusting, mopping, sanitization',
                              ),
                              maxLines: 3,
                              validator: (value) =>
                              value?.trim().isEmpty ?? true ? 'Please enter a description' : null,
                              onFieldSubmitted: (value) {
                                FocusScope.of(context).requestFocus(_priceFocusNode);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              focusNode: _priceFocusNode,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                hintText: 'Enter service price',
                                prefixText: '₹ ',
                              ),
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) return 'Please enter a price';
                                if (double.tryParse(value!) == null) return 'Please enter a valid number';
                                return null;
                              },
                              onFieldSubmitted: (value) {
                                FocusScope.of(context).nextFocus();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category & Subcategory Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Category & Subcategory', FontAwesomeIcons.list),
                            DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
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
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedSubcategory,
                              decoration: const InputDecoration(
                                labelText: 'Subcategory',
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
                    const SizedBox(height: 16),

                    // What's Included Section
                    _buildDynamicList(
                      'What\'s Included',
                      'e.g., Free consultation, Cleaning tools',
                      whatsIncludedList,
                      _whatsIncludedController,
                      _whatsIncludedFocusNode,
                    ),
                    const SizedBox(height: 16),

                    // Responsibilities Section
                    _buildDynamicList(
                      'Responsibilities',
                      'e.g., Arrive on time, Complete tasks',
                      responsibilitiesList,
                      _responsibilitiesController,
                      _responsibilitiesFocusNode,
                    ),
                    const SizedBox(height: 16),

                    // Images Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Images', FontAwesomeIcons.images),
                            Text(
                              '${selectedImages.length}/5 images selected',
                              style: const TextStyle(color: ProviderTheme.secondaryTextColor),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedImages
                                  .map(
                                    (image) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        image,
                                        height: 80,
                                        width: 80,
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
                                            color: ProviderTheme.canceledColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const FaIcon(
                                            FontAwesomeIcons.xmark,
                                            color: ProviderTheme.onPrimaryTextColor,
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
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: selectImages,
                              icon: FaIcon(FontAwesomeIcons.image, size: 20, color: ProviderTheme.onPrimaryTextColor.withOpacity(0.7),),
                              label: const Text('Add Images'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: ProviderTheme.primaryColor.withOpacity(0.4), // Lighter color
                                  foregroundColor: ProviderTheme.onPrimaryTextColor.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submission Note
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Your service will be reviewed by our team before being published.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProviderTheme.primaryColor.withOpacity(0.5), // Lighter color
                          foregroundColor: ProviderTheme.onPrimaryTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: ProviderTheme.primaryTextColor)
                            : const Text('Submit Service'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}