import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddServiceScreen extends StatefulWidget {
  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? selectedCategory;
  String? selectedSubcategory;
  List<String> subcategories = [];
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  List<String> whatsIncludedList = [];
  List<String> responsibilitiesList = [];
  final TextEditingController _dynamicFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  List<String> categories = [];

  Future<void> fetchCategories() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchSubcategories(String categoryName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          // Map subcategories to extract their names
          subcategories = (snapshot.docs.first['subcategories'] as List)
              .map<String>((subcategory) => subcategory['name'] as String)
              .toList();
          selectedSubcategory = null; // Reset selected subcategory
        });
      } else {
        setState(() {
          subcategories = [];
          selectedSubcategory = null;
        });
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
      setState(() {
        subcategories = [];
        selectedSubcategory = null;
      });
    }
  }


  Future<void> selectImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null &&
        pickedFiles.length + selectedImages.length <= 5) {
      setState(() {
        selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only select up to 5 images.')),
      );
    }
  }

  Future<List<String>> uploadImagesToCloudinary() async {
    List<String> imageUrls = [];
    const String cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dpcjw0g5c/image/upload';
    const String uploadPreset = 'flutter_unsigned_upload';

    for (var image in selectedImages) {
      try {
        String fileName = const Uuid().v4();
        var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
        request.fields['upload_preset'] = uploadPreset;
        request.files
            .add(await http.MultipartFile.fromPath('file', image.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseBody);
          if (jsonResponse['secure_url'] != null) {
            imageUrls.add(jsonResponse['secure_url']);
            print('Uploaded image URL: ${jsonResponse['secure_url']}');
          } else {
            print('Error: secure_url not found in response.');
          }
        } else {
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        print('Exception during image upload: $e');
      }
    }
    return imageUrls;
  }

  Future<void> submitService() async {
    if (_formKey.currentState!.validate() &&
        selectedCategory != null &&
        selectedSubcategory != null) {
      setState(() {
        isLoading = true;
      });
      try {
        // Get the current provider ID
        String? providerId = FirebaseAuth.instance.currentUser?.uid;

        if (providerId == null) {
          throw Exception('No provider logged in');
        }

        // Upload images
        List<String> imageUrls = await uploadImagesToCloudinary();

        // Add service to Pending Services Collection
        DocumentReference pendingServiceRef =
        await FirebaseFirestore.instance.collection('pending_services').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'category': selectedCategory,
          'subcategory': selectedSubcategory,
          'price': double.parse(_priceController.text),
          'whatsIncluded': whatsIncludedList,
          'responsibilities': responsibilitiesList,
          'images': imageUrls,
          'createdBy': providerId, // Dynamically set provider ID
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending', // Mark as pending for admin approval
        });

        // Notify user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service submitted for approval!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error adding service: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit service.')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildDynamicList(String label, String hint, List<String> itemsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: itemsList.map((item) {
            return Chip(
              label: Text(item),
              deleteIcon: Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  itemsList.remove(item);
                });
              },
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _dynamicFieldController,
          decoration: InputDecoration(
            hintText: '$hint',
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                if (_dynamicFieldController.text.isNotEmpty) {
                  setState(() {
                    itemsList.add(_dynamicFieldController.text.trim());
                    _dynamicFieldController.clear();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Service'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Service Name',
                        hintText: 'E.g., Home Cleaning, AC Repair',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a service name' : null,
                    ),
                    SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'E.g., Includes dusting, mopping, sanitization',
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: 'Enter service price',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a price' : null,
                    ),
                    SizedBox(height: 16),

                    // Categories
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((category) => DropdownMenuItem(
                              value: category, child: Text(category)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          fetchSubcategories(value!);
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    SizedBox(height: 16),

                    // Subcategories
                    DropdownButtonFormField<String>(
                      value: selectedSubcategory,
                      decoration: InputDecoration(labelText: 'Subcategory'),
                      items: subcategories
                          .map((subcategory) => DropdownMenuItem(
                        value: subcategory,
                        child: Text(subcategory),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubcategory = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a subcategory' : null,
                    ),

                    SizedBox(height: 16),

                    // What's Included
                    _buildDynamicList('What\'s Included', 'E.g., Free consultation, Cleaning tools, Basic setup', whatsIncludedList),
                    SizedBox(height: 16),

                    // Responsibilities
                    _buildDynamicList('Responsibilities', 'E.g., Arrive on time, Complete tasks, Ensure satisfaction', responsibilitiesList),
                    SizedBox(height: 16),

                    // Images
                    Text(
                      'Images',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedImages.map((image) {
                        return Stack(
                          children: [
                            Image.file(image,
                                height: 100, width: 100, fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImages.remove(image);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: selectImages,
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Add Images'),
                    ),
                    SizedBox(height: 24),

                    // Add Service Button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: submitService,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                        child: Text('Add Service'),
                      ),
                    ),
                    SizedBox(height: 32), // Extra bottom padding for scrolling
                  ],
                ),
              ),
            ),
    );
  }
}
