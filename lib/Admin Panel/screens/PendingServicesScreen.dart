import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Admin%20Panel/screens/pending_service_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class PendingServicesScreen extends StatefulWidget {
  @override
  _PendingServicesScreenState createState() => _PendingServicesScreenState();
}

class _PendingServicesScreenState extends State<PendingServicesScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Future<List<Map<String, dynamic>>> _servicesFuture;
  String _filterCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _servicesFuture = _fetchPendingServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _servicesFuture = _fetchPendingServices();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPendingServices() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('pending_services')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> services = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        if (data['createdAt'] != null) {
          final timestamp = data['createdAt'] as Timestamp;
          data['formattedDate'] = DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
        } else {
          data['formattedDate'] = 'Date unavailable';
        }
        return data;
      }).toList();

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        services = services.where((service) =>
        (service['name']?.toString().toLowerCase() ?? '').contains(query) ||
            (service['category']?.toString().toLowerCase() ?? '').contains(query) ||
            (service['subcategory']?.toString().toLowerCase() ?? '').contains(query)
        ).toList();
      }

      if (_filterCategory != 'All') {
        services = services.where((service) => service['category'] == _filterCategory).toList();
      }

      return services;
    } catch (e) {
      print('Error fetching pending services: $e');
      return [];
    }
  }

  Future<void> _refreshServices() async {
    setState(() {
      _servicesFuture = _fetchPendingServices();
    });
  }

  void _updateServiceStatus(String serviceId, String status, Map<String, dynamic> serviceData) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              ),
              SizedBox(width: 16),
              Text('Processing request...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      if (status == 'Approved') {
        await FirebaseFirestore.instance.collection('services').doc(serviceId).set({
          ...serviceData,
          'status': 'Approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service approved successfully'), backgroundColor: Colors.green),
        );
      } else if (status == 'Declined') {
        await FirebaseFirestore.instance.collection('declined_services').doc(serviceId).set({
          ...serviceData,
          'status': 'Declined',
          'declinedAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('pending_services').doc(serviceId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service declined'), backgroundColor: Colors.red),
        );
      }

      setState(() {
        _servicesFuture = _fetchPendingServices();
      });
    } catch (e) {
      print('Error updating service status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not update service status'), backgroundColor: Colors.red),
      );
    }
  }

  List<String> _getCategories(List<Map<String, dynamic>> services) {
    Set<String> categories = {'All'};
    for (var service in services) {
      if (service['category'] != null && service['category'].toString().isNotEmpty) {
        categories.add(service['category'].toString());
      }
    }
    return categories.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Pending Services'),
        backgroundColor: Color(0xFF060644),
        actions: [

        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshServices,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _servicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerEffect();
                  if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
                  return _buildServicesList(snapshot.data!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      color: Color(0xFF060644),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox.shrink();
              List<String> categories = _getCategories(snapshot.data!);
              return Container(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _filterCategory == category,
                        selectedColor: Colors.white, // Selected background color
                        backgroundColor: Color(0xFF060644), // Unselected background color
                        labelStyle: TextStyle(
                          color: _filterCategory == category
                              ? Color(0xFF060644) // Selected text color
                              : Colors.white, // Unselected text color
                          fontWeight: _filterCategory == category
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filterCategory = category;
                            _servicesFuture = _fetchPendingServices();
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<Map<String, dynamic>> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: services.length,
      itemBuilder: (context, index) => _buildServiceCard(services[index]),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Slidable(
      key: ValueKey(service['id']),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _updateServiceStatus(service['id'], 'Approved', service),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check_circle,
            label: 'Approve',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _updateServiceStatus(service['id'], 'Declined', service),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.cancel,
            label: 'Decline',
          ),
        ],
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingServiceDetailsScreen(serviceId: service['id']),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: service['imageUrl'] != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          service['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                        ),
                      )
                          : Center(
                        child: Icon(
                          Icons.home_repair_service,
                          color: Colors.indigo.shade400,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF060644),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              service['category'] ?? 'N/A',
                              style: TextStyle(fontSize: 12, color: Colors.indigo.shade700),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            service['subcategory'] ?? 'N/A',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          service['formattedDate'],
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      '₹${service['price']?.toString() ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Provider: ${service['providerName'] ?? 'Unknown Provider'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PendingServiceDetailsScreen(serviceId: service['id']),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade700,
                        side: BorderSide(color: Colors.indigo.shade200),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 60, height: 60, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 18, width: 150, color: Colors.white),
                        SizedBox(height: 6),
                        Container(height: 12, width: 80, color: Colors.white),
                        SizedBox(height: 4),
                        Container(height: 12, width: 100, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 14, width: 100, color: Colors.white),
                  Container(height: 16, width: 60, color: Colors.white),
                ],
              ),
              SizedBox(height: 8),
              Container(height: 13, width: 180, color: Colors.white),
              SizedBox(height: 12),
              Container(height: 36, width: 120, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No pending services found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            'All caught up! Check back later',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            onPressed: _refreshServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            onPressed: _refreshServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}