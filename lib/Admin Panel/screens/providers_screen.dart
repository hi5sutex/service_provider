import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:service_provider/Admin%20Panel/screens/provider_details_screen.dart';
import 'package:intl/intl.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({Key? key}) : super(key: key);

  @override
  _ProvidersScreenState createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  bool hasViewPermission = false;
  bool hasManagePermission = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allProviders = [];
  List<Map<String, dynamic>> filteredProviders = [];
  bool isLoading = true;
  String sortBy = 'name';
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      hasViewPermission = true;
      hasManagePermission = true;
    });
  }

  Future<void> _loadProviders() async {
    if (!hasViewPermission) return;

    setState(() {
      isLoading = true;
    });

    try {
      final providers = await _fetchProviders();
      setState(() {
        allProviders = providers;
        filteredProviders = providers;
        isLoading = false;
      });
      _sortProviders();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load providers: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadProviders,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProviders() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('providers').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  void _filterProviders(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredProviders = allProviders.where((provider) {
        final name = (provider['name'] ?? '').toString().toLowerCase();
        final email = (provider['email'] ?? '').toString().toLowerCase();
        final phone = (provider['phone'] ?? '').toString().toLowerCase();
        final services = (provider['services'] ?? []).join(' ').toLowerCase();
        return name.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery) ||
            services.contains(searchQuery);
      }).toList();
      _sortProviders();
    });
  }

  void _sortProviders() {
    filteredProviders.sort((a, b) {
      dynamic valueA, valueB;

      if (sortBy == 'name') {
        valueA = a['name'] ?? '';
        valueB = b['name'] ?? '';
      } else if (sortBy == 'email') {
        valueA = a['email'] ?? '';
        valueB = b['email'] ?? '';
      } else if (sortBy == 'date') {
        valueA = a['createdAt'] is Timestamp ? a['createdAt'].toDate() : DateTime(2000);
        valueB = b['createdAt'] is Timestamp ? b['createdAt'].toDate() : DateTime(2000);
      }

      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = 0;
      }

      return sortAscending ? comparison : -comparison;
    });
  }

  void _updateSortCriteria(String criteria) {
    setState(() {
      if (sortBy == criteria) {
        sortAscending = !sortAscending;
      } else {
        sortBy = criteria;
        sortAscending = true;
      }
      _sortProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort providers',
            icon: const Icon(Icons.sort),
            onSelected: _updateSortCriteria,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      sortBy == 'name'
                          ? (sortAscending ? Icons.arrow_downward : Icons.arrow_upward)
                          : Icons.sort,
                      size: 18,
                      color: sortBy == 'name' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'email',
                child: Row(
                  children: [
                    Icon(
                      sortBy == 'email'
                          ? (sortAscending ? Icons.arrow_downward : Icons.arrow_upward)
                          : Icons.sort,
                      size: 18,
                      color: sortBy == 'email' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Email'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      sortBy == 'date'
                          ? (sortAscending ? Icons.arrow_downward : Icons.arrow_upward)
                          : Icons.sort,
                      size: 18,
                      color: sortBy == 'date' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Join Date'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: !hasViewPermission
          ? _buildNoPermissionView()
          : Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading ? _buildShimmerEffect(isSmallScreen) : _buildProvidersList(isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to view providers.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, email, phone or services',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _filterProviders('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: _filterProviders,
      ),
    );
  }

  Widget _buildProvidersList(bool isSmallScreen) {
    if (filteredProviders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? 'No providers found' : 'No matching providers found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (searchQuery.isNotEmpty) const SizedBox(height: 8),
            if (searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _filterProviders('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 2,
        childAspectRatio: isSmallScreen ? 1.6 : 1.8,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: filteredProviders.length,
      itemBuilder: (context, index) => _buildProviderCard(filteredProviders[index]),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        onTap: hasManagePermission
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailsScreen(providerId: provider['id']),
            ),
          ).then((_) => _loadProviders());
        }
            : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(provider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProviderInfo(provider),
                    _buildStatusRow(provider),
                  ],
                ),
              ),
              if (hasManagePermission)
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderDetailsScreen(providerId: provider['id']),
                      ),
                    ).then((_) => _loadProviders());
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> provider) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(
            provider['profileImage'] ??
                'https://res.cloudinary.com/dpcjw0g5c/image/upload/v1735399079/icons8-user-default-100_hakusn.png',
          ),
          backgroundColor: Colors.grey.shade200,
        ),
        if (provider['isVerified'] ?? false)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified, size: 16, color: Colors.white),
            ),
          )
      ],
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic> provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider['name'] ?? 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.email_outlined, provider['email']),
        _buildInfoRow(Icons.phone_android_outlined, provider['phone']),
        if (provider['services'] != null && provider['services'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.work_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider['services'].join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Map<String, dynamic> provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildStatusChip('Joined', _formatTimestamp(provider['createdAt'])),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect(bool isSmallScreen) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 2,
        childAspectRatio: isSmallScreen ? 1.6 : 1.8,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300!,
        highlightColor: Colors.grey.shade100!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                    )),
                    const SizedBox(height: 8),
                    Container(
                      height: 24,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    )
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
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}