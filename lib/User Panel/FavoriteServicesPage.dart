import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';
import 'package:service_provider/User Panel/service_details_screen.dart';
class FavoriteServicesPage extends StatefulWidget {
  @override
  _FavoriteServicesPageState createState() => _FavoriteServicesPageState();
}

class _FavoriteServicesPageState extends State<FavoriteServicesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _favoriteServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteServices();
  }

  Future<void> _fetchFavoriteServices() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        List<dynamic> favoriteServiceIds = userDoc['favser'] ?? [];
        List<Map<String, dynamic>> services = [];

        for (String serviceId in favoriteServiceIds) {
          DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .get();

          if (serviceDoc.exists) {
            services.add({
              'id': serviceId,
              ...serviceDoc.data() as Map<String, dynamic>,
            });
          }
        }

        setState(() {
          _favoriteServices = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching favorite services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF060644),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favorite Services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerEffect(screenWidth, screenHeight)
          : _favoriteServices.isEmpty
          ? _buildEmptyState(screenWidth)
          : _buildServiceList(screenWidth, screenHeight),
    );
  }

  Widget _buildShimmerEffect(double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: 5, // Number of shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
            child: ListTile(
              leading: CircleAvatar(
                radius: screenWidth * 0.06,
                backgroundColor: Colors.grey[300],
              ),
              title: Container(
                width: screenWidth * 0.4,
                height: 16,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                width: screenWidth * 0.2,
                height: 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: screenWidth * 0.15,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorite Services Yet',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add services to your favorites to see them here',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: _fetchFavoriteServices,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _favoriteServices.length,
        itemBuilder: (context, index) {
          final service = _favoriteServices[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsScreen(
                      serviceId: service['id'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: service['images'] != null &&
                          (service['images'] as List).isNotEmpty
                          ? Image.network(
                        service['images'][0],
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultImage(screenWidth),
                      )
                          : _buildDefaultImage(screenWidth),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? 'Unnamed Service',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A237E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            service['category'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            '₹${service['price']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF1A237E),
                      size: screenWidth * 0.045,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultImage(double screenWidth) {
    return Container(
      width: screenWidth * 0.15,
      height: screenWidth * 0.15,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.build,
        color: Colors.grey[600],
        size: screenWidth * 0.06,
      ),
    );
  }
}