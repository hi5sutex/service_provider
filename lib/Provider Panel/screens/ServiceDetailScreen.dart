import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:service_provider/Provider Panel/CustomSnackBar.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomSnackBar(
              message: 'Failed to load service details',
              type: 'error',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const CustomSnackBar(
                message: 'Maximum 5 images allowed',
                type: 'error',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomSnackBar(
              message: 'Service updated successfully!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const CustomSnackBar(
              message: 'Failed to update service',
              type: 'error',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDynamicList(String label, List<String> itemsList, TextEditingController controller) {
    return Card(
      elevation: 2,
      color: ProviderTheme.surfaceColor, // White card background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProviderTheme.primaryTextColor, // Dark Navy Blue
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itemsList.map((item) {
                return Chip(
                  label: Text(
                    item,
                    style: const TextStyle(color: ProviderTheme.onPrimaryTextColor), // White text
                  ),
                  backgroundColor: ProviderTheme.primaryColor.withOpacity(0.4), // Dark Navy Blue
                  deleteIcon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: ProviderTheme.onPrimaryTextColor, // White icon
                    size: 16,
                  ),
                  onDeleted: () => setState(() => itemsList.remove(item)),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add new $label',
                hintStyle: TextStyle(color: ProviderTheme.secondaryTextColor), // Gray hint
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ProviderTheme.primaryColor), // Dark Navy Blue on focus
                ),
                suffixIcon: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.plus,
                    color: ProviderTheme.primaryColor, // Dark Navy Blue icon
                  ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor, // Light Gray background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient, // Gradient background
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: ProviderTheme.surfaceColor, // White arrow
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Service Details',
          style: TextStyle(color: ProviderTheme.onPrimaryTextColor), // White text
        ),
        centerTitle: false,
        elevation: 4,
        shadowColor: ProviderTheme.shadowColor.withOpacity(0.4), // Shadow effect
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
              // Image Section
              Card(
                elevation: 2,
                color: ProviderTheme.surfaceColor, // White card background
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (existingImageUrls.isNotEmpty || newImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: existingImageUrls.length + newImages.length,
                          itemBuilder: (context, index) {
                            if (index < existingImageUrls.length) {
                              String url = existingImageUrls[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: ProviderTheme.cardHighlightColor, // Light Gray fallback
                                        child: Center(
                                          child: FaIcon(
                                            FontAwesomeIcons.image,
                                            color: ProviderTheme.secondaryTextColor, // Gray icon
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.trashCan,
                                        color: ProviderTheme.errorTextColor, // Crimson Red
                                        size: 20,
                                      ),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.trashCan,
                                        color: ProviderTheme.errorTextColor, // Crimson Red
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => newImages.removeAt(newIndex)),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        )
                      else
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: ProviderTheme.cardHighlightColor, // Light Gray placeholder
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No images added',
                              style: TextStyle(color: ProviderTheme.secondaryTextColor), // Gray text
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final pickedFiles = await _picker.pickMultiImage();
                            if (pickedFiles != null) {
                              setState(() {
                                newImages.addAll(pickedFiles.map((e) => File(e.path)));
                              });
                            }
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.camera,
                            color: ProviderTheme.onPrimaryTextColor, // White icon
                          ),
                          label: const Text(
                            'Add Images',
                            style: TextStyle(color: ProviderTheme.onPrimaryTextColor), // White text
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProviderTheme.secondaryColor, // Steel Blue
                            foregroundColor: ProviderTheme.onPrimaryTextColor, // White
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Service Details Section
              Card(
                elevation: 2,
                color: ProviderTheme.surfaceColor, // White card background
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Service Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Name',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: ProviderTheme.primaryColor), // Dark Navy Blue on focus
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter service name' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: ProviderTheme.primaryColor), // Dark Navy Blue on focus
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter description' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: const TextStyle(color: ProviderTheme.successColor), // Forest Green for currency symbol
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: ProviderTheme.primaryColor), // Dark Navy Blue on focus
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter price' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Category and Subcategory (Read-only)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                                    borderRadius: BorderRadius.circular(8),
                                    color: ProviderTheme.cardHighlightColor, // Very Light Gray background
                                  ),
                                  child: Text(
                                    category ?? 'N/A',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: ProviderTheme.secondaryTextColor, // Gray text
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subcategory',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                                    borderRadius: BorderRadius.circular(8),
                                    color: ProviderTheme.cardHighlightColor, // Very Light Gray background
                                  ),
                                  child: Text(
                                    subcategory ?? 'N/A',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: ProviderTheme.secondaryTextColor, // Gray text
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Created At (Read-only)
                      if (createdAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created At',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 14,
                                color: ProviderTheme.primaryTextColor, // Dark Navy Blue
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: ProviderTheme.secondaryTextColor.withOpacity(0.5)), // Light Gray border
                                borderRadius: BorderRadius.circular(8),
                                color: ProviderTheme.cardHighlightColor, // Very Light Gray background
                              ),
                              child: Text(
                                createdAt!.toDate().toString(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ProviderTheme.secondaryTextColor, // Gray text
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dynamic Lists
              _buildDynamicList("What's Included", whatsIncluded, _newWhatsIncludedController),
              const SizedBox(height: 16),
              _buildDynamicList('Responsibilities', responsibilities, _newResponsibilitiesController),
              const SizedBox(height: 24),
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProviderTheme.secondaryColor, // Steel Blue
                    foregroundColor: ProviderTheme.onPrimaryTextColor, // White
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: ProviderTheme.onPrimaryTextColor)
                      : const Text(
                    'Update Service',
                    style: TextStyle(fontSize: 16),
                  ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: ProviderTheme.secondaryTextColor.withOpacity(0.3), // Slightly darker gray for base
        highlightColor: ProviderTheme.cardHighlightColor, // Light Gray for highlight
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section Placeholder
            Card(
              elevation: 2,
              shadowColor: ProviderTheme.shadowColor.withOpacity(0.2), // Subtle shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 200,
                color: ProviderTheme.surfaceColor, // White background
              ),
            ),
            const SizedBox(height: 16),
            // Service Details Placeholder
            Card(
              elevation: 2,
              shadowColor: ProviderTheme.shadowColor.withOpacity(0.2), // Subtle shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 300,
                color: ProviderTheme.surfaceColor, // White background
              ),
            ),
            const SizedBox(height: 16),
            // Dynamic Lists Placeholder
            Card(
              elevation: 2,
              shadowColor: ProviderTheme.shadowColor.withOpacity(0.2), // Subtle shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 150,
                color: ProviderTheme.surfaceColor, // White background
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shadowColor: ProviderTheme.shadowColor.withOpacity(0.2), // Subtle shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 150,
                color: ProviderTheme.surfaceColor, // White background
              ),
            ),
            const SizedBox(height: 16),
            // Button Placeholder
            Container(
              height: 50,
              color: ProviderTheme.surfaceColor, // White background
            ),
          ],
        ),
      ),
    );
  }
}