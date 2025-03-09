import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({required this.serviceId, Key? key}) : super(key: key);

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<File> newImages = [];
  List<String> existingImageUrls = [];
  bool isLoading = true;

  // Controllers for service details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _newWhatsIncludedController = TextEditingController();
  final TextEditingController _newResponsibilitiesController = TextEditingController();

  String? category;
  String? subcategory;
  List<String> whatsIncluded = [];
  List<String> responsibilities = [];
  Timestamp? createdAt;

  @override
  void initState() {
    super.initState();
    fetchServiceDetails();
  }

  Future<void> fetchServiceDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        Map<String, dynamic> data = serviceSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'];
          _descriptionController.text = data['description'];
          _priceController.text = data['price'].toString();
          category = data['category'];
          subcategory = data['subcategory'];
          whatsIncluded = List<String>.from(data['whatsIncluded']);
          responsibilities = List<String>.from(data['responsibilities']);
          existingImageUrls = List<String>.from(data['images']);
          createdAt = data['createdAt'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching service details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load service details')),
      );
    }
  }

  Future<List<String>> uploadImagesToCloudinary(List<File> images) async {
    List<String> imageUrls = [];
    const String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dpcjw0g5c/image/upload';
    const String uploadPreset = 'flutter_unsigned_upload';

    for (var image in images) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseBody);
          final secureUrl = jsonResponse['secure_url'] as String?;
          if (secureUrl != null) imageUrls.add(secureUrl);
        } else {
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
      }
    }
    return imageUrls;
  }

  Future<void> updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      List<String> newImageUrls = await uploadImagesToCloudinary(newImages);
      List<String> allImageUrls = [...existingImageUrls, ...newImageUrls];

      if (allImageUrls.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 images allowed')),
        );
        setState(() => isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('services').doc(widget.serviceId).update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': category,
        'subcategory': subcategory,
        'whatsIncluded': whatsIncluded,
        'responsibilities': responsibilities,
        'images': allImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update service')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDynamicList(String label, List<String> itemsList, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF060644),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itemsList.map((item) {
              return Chip(
                label: Text(item, style: const TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xFF060644),
                deleteIcon: const Icon(Icons.close, color: Colors.white),
                onDeleted: () => setState(() => itemsList.remove(item)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Add new $label',
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF060644)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF060644)),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    setState(() {
                      itemsList.add(controller.text.trim());
                      controller.clear();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF060644),
        title: const Text('Service Details', style: TextStyle(color: Colors.white)),
        elevation: 4,
      ),
      body: isLoading
          ? const ServiceDetailShimmer()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Management
              if (existingImageUrls.isNotEmpty || newImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: existingImageUrls.length + newImages.length,
                  itemBuilder: (context, index) {
                    if (index < existingImageUrls.length) {
                      String url = existingImageUrls[index];
                      return Stack(
                        children: [
                          Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => existingImageUrls.removeAt(index)),
                            ),
                          ),
                        ],
                      );
                    } else {
                      int newIndex = index - existingImageUrls.length;
                      File file = newImages[newIndex];
                      return Stack(
                        children: [
                          Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => newImages.removeAt(newIndex)),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final pickedFiles = await _picker.pickMultiImage();
                  if (pickedFiles != null) {
                    setState(() {
                      newImages.addAll(pickedFiles.map((e) => File(e.path)));
                    });
                  }
                },
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                label: const Text('Add Images', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF060644)),
              ),
              const SizedBox(height: 16),
              // Service Name
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF060644))),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF060644)),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter service name' : null,
                    ),
                  ],
                ),
              ),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF060644))),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF060644)),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter description' : null,
                    ),
                  ],
                ),
              ),
              // Price
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF060644))),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF060644)),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Enter price' : null,
                    ),
                  ],
                ),
              ),
              // Dynamic Lists
              _buildDynamicList("What's Included", whatsIncluded, _newWhatsIncludedController),
              _buildDynamicList('Responsibilities', responsibilities, _newResponsibilitiesController),
              const SizedBox(height: 16),
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF060644),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Service', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer Effect Widget
class ServiceDetailShimmer extends StatelessWidget {
  const ServiceDetailShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 200, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 50, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 100, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 50, color: Colors.white),
          ],
        ),
      ),
    );
  }
}