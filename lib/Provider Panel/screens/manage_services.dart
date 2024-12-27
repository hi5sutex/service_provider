import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';

class ManageServices extends StatefulWidget {
  const ManageServices({Key? key}) : super(key: key);

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {
  late final String providerId;

  @override
  void initState() {
    super.initState();
    providerId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<List<Map<String, dynamic>>> fetchServices() async {
    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();

      if (!providerDoc.exists) return [];

      List<dynamic> serviceIds = providerDoc.data()?['servicesOffered'] ?? [];
      List<Map<String, dynamic>> services = [];

      for (String serviceId in serviceIds) {
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get();

        if (serviceDoc.exists) {
          Map<String, dynamic> serviceData =
          serviceDoc.data() as Map<String, dynamic>;
          serviceData['id'] = serviceDoc.id; // Add the ID to the data
          services.add(serviceData);
        }
      }

      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(child: Text('No services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceItem(service: service);
            },
          );
        },
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceItem({required this.service, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final images = service['images'] ?? [];
    final displayImage = images.isNotEmpty ? images[0] : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceDetailScreen(serviceId: service['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: displayImage != null
                      ? Image.network(
                    displayImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${images.length - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? 'Service Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${service['price'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        service['category'] ?? 'Category',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service['subcategory'] ?? 'Subcategory',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  ServiceDetailScreen({required this.serviceId});

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
  final TextEditingController _newWhatsIncludedController =
  TextEditingController();
  final TextEditingController _newResponsibilitiesController =
  TextEditingController();

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
        Map<String, dynamic> data =
        serviceSnapshot.data() as Map<String, dynamic>;
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
      print('Error fetching service details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load service details')),
      );
    }
  }

  Future<void> updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': category,
        'subcategory': subcategory,
        'whatsIncluded': whatsIncluded,
        'responsibilities': responsibilities,
        'images': existingImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error updating service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update service')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildDynamicList(
      String label, List<String> itemsList, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Add new item',
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
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
        title: Text('Service Details'),
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
              // Image Slider
              if (existingImageUrls.isNotEmpty)
                CarouselSlider(
                  items: existingImageUrls.map((url) {
                    return Image.network(url, fit: BoxFit.cover);
                  }).toList(),
                  options: CarouselOptions(
                    height: 200,
                    enlargeCenterPage: true,
                  ),
                ),
              SizedBox(height: 16),
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Service Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter service name' : null,
              ),
              SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) =>
                value!.isEmpty ? 'Enter description' : null,
              ),
              SizedBox(height: 16),
              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
                validator: (value) =>
                value!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 16),
              // Dynamic Lists
              _buildDynamicList(
                  "What's Included", whatsIncluded, _newWhatsIncludedController),
              SizedBox(height: 16),
              _buildDynamicList('Responsibilities', responsibilities,
                  _newResponsibilitiesController),
              SizedBox(height: 16),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateService,
                  child: Text('Update Service'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

