import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/provider_details_screen.dart';

class ProvidersScreen extends StatefulWidget {
  @override
  _ProvidersScreenState createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
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

  Future<List<Map<String, dynamic>>> _fetchProviders() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('providers').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the provider data
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Providers'),
      ),
      body: hasViewPermission
          ? FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading providers.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No providers found.'));
          }

          final providers = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return _buildProviderCard(provider);
            },
          );
        },
      )
          : Center(
        child: Text(
          'You do not have permission to view providers.',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
      floatingActionButton: hasManagePermission
          ? FloatingActionButton(
        onPressed: () {
          // Implement add provider or other management functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Manage Providers functionality coming soon!')),
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

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return GestureDetector(
      onTap: hasManagePermission
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderDetailsScreen(providerId: provider['id']),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(provider['profileImage'] ??
                    'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png'),
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider['email'] ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider['phone'] ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined: ${_formatTimestamp(provider['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
