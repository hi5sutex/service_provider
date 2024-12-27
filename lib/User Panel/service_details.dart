import 'package:flutter/material.dart';

class DetailedServicePage extends StatelessWidget {
  final String serviceName;
  final String category;
  final double price;
  final String description;
  final List<String> responsibilities;
  final String subcategory;
  final List<String> whatsIncluded;
  final List<String> images;

  const DetailedServicePage({
    required this.serviceName,
    required this.category,
    required this.price,
    required this.description,
    required this.responsibilities,
    required this.subcategory,
    required this.whatsIncluded,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ // Image carousel with swipe functionality
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child:
                              Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16), // Fixed-width card with dynamic height
              SizedBox(
                width: double.infinity, // Full width of the parent container
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [ // Service Name
                        Text(
                          serviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 8), // Category and Subcategory
                        Text(
                          'Category: $category',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 16),
                        ),
                        Text(
                          'Subcategory: $subcategory',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 16),
                        ),
                        SizedBox(height: 16), // Price
                        Text(
                          '\$$price',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 16), // Description
                        Text(
                          description,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24), // Book Now button
              Center(
                child: ElevatedButton(
                  onPressed: () {// Handle book now action
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(fontSize: 18),
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
