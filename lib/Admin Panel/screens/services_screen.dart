import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/service_details_screen.dart';

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool hasViewPermission = false;
  bool hasManagePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Simulated permission check (replace with real logic)
    // Example: Fetch admin permissions from Firebase or a local store
    setState(() {
      hasViewPermission = true; // Example: Replace with actual permission
      hasManagePermission = true; // Example: Replace with actual permission
    });
  }

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('services').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the service data
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
      ),
      body: hasViewPermission
          ? FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading services.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No services found.'));
          }

          final services = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service);
            },
          );
        },
      )
          : Center(
        child: Text(
          'You do not have permission to view services.',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
      floatingActionButton: hasManagePermission
          ? FloatingActionButton(
        onPressed: () {
          // Implement add service or other management functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Manage Services functionality coming soon!')),
          );
        },
        backgroundColor: Colors.lightBlue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      )
          : null,
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: hasManagePermission
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceId: service['id']),
          ),
        );
      }
          : null,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service['name'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service['category'] ?? 'N/A',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                service['subcategory'] ?? 'N/A',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: ₹${service['price']?.toString() ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
