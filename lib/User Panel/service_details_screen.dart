import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? providerData;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchServiceAndProviderDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceAndProviderDetails() async {
    try {
      DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (serviceSnapshot.exists) {
        serviceData = serviceSnapshot.data() as Map<String, dynamic>;
        String providerId = serviceData!['createdBy'];

        DocumentSnapshot providerSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .get();

        if (providerSnapshot.exists) {
          setState(() {
            providerData = providerSnapshot.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print('Error fetching service or provider details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(serviceData?['name'] ?? 'Service Details'),
        backgroundColor: Colors.blue,
      ),
      body: serviceData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Slider with Dots Indicator
              _buildImageSlider(),
              SizedBox(height: 16),

              // Service Details Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceData!['name'] ?? 'Unnamed Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Category: ${serviceData!['category'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '₹${serviceData!['price']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        serviceData!['description'] ?? 'No description available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // What's Included Section
              if ((serviceData!['whatsIncluded'] as List<dynamic>?)?.isNotEmpty ?? false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's Included",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...(serviceData!['whatsIncluded'] as List<dynamic>).map(
                              (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(child: Text(item.toString())),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Responsibilities Section
              if ((serviceData!['responsibilities'] as List<dynamic>?)?.isNotEmpty ?? false)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsibilities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...(serviceData!['responsibilities'] as List<dynamic>).map(
                              (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_right, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(child: Text(item.toString())),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Additional Information Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.access_time, color: Colors.blue),
                        title: Text('Flexible Scheduling'),
                        subtitle: Text('Book at your convenient time'),
                      ),
                      ListTile(
                        leading: Icon(Icons.verified_user, color: Colors.blue),
                        title: Text('Verified Providers'),
                        subtitle: Text('All providers are verified and trusted'),
                      ),
                      ListTile(
                        leading: Icon(Icons.thumb_up, color: Colors.blue),
                        title: Text('Satisfaction Guaranteed'),
                        subtitle: Text('Quality service or money back'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Provider Information
              if (providerData != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Provider',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(providerData!['name'] ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(providerData!['phone'] ?? 'N/A'),
                              Text(providerData!['email'] ?? 'N/A'),
                              Text(providerData!['address']?['string'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    final List<String> images = (serviceData!['images'] as List<dynamic>?)?.cast<String>() ?? [];

    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: _currentPage == index ? 8.0 : 5.0,
              height: _currentPage == index ? 8.0 : 5.0,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}