import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:service_provider/User%20Panel/provider_services_page.dart';
import 'package:service_provider/User%20Panel/subcategories_list.dart';
import 'package:service_provider/User%20Panel/user_profile.dart';
import 'package:service_provider/User%20Panel/service_details_screen.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

class UserHome extends StatefulWidget {
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with AutomaticKeepAliveClientMixin {
  String selectedCategory = 'All';
  String userCity = 'Loading...';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profileImageUrl;
  final TextEditingController _searchController = TextEditingController();
  List<Service> _searchResults = [];
  bool _showSuggestions = false;
  final FocusNode _searchFocusNode = FocusNode();
  List<Service> _allServices = [];
  Timer? _searchDebounceTimer;
  bool _isLoadingServices = false;
  bool _isLoadingCategories = true;
  bool _isLoadingBanners = true; // New flag for banner loading

  Future<String> getUserName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc['name'] ?? 'User';
      } else {
        return 'User not logged in';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Error';
    }
  }

  Future<void> _fetchProfilePic() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _profileImageUrl = userDoc['profileImage'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
    }
  }

  void _changeStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: UserTheme.primaryColor,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Stream<List<Service>> getServices(String category) {
    Query query = FirebaseFirestore.instance.collection('services');
    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  Future<void> _searchServices(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    _searchDebounceTimer?.cancel();

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      setState(() {
        _searchResults = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
        _showSuggestions = true;
      });
    } catch (e) {
      print('Error searching services: $e');
    }
  }

  Future<void> _prefetchServices() async {
    if (_allServices.isNotEmpty) return;

    try {
      setState(() => _isLoadingServices = true);
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .limit(50)
          .get();

      setState(() {
        _allServices = snapshot.docs
            .map((doc) => Service.fromFirestore(doc))
            .toList();
      });

      _loadMoreServices();
    } catch (e) {
      print('Error prefetching services: $e');
    } finally {
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _loadMoreServices() async {
    if (_allServices.isEmpty) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('services')
          .startAfterDocument(_allServices.last as DocumentSnapshot<Object?>)
          .limit(50)
          .get();

      setState(() {
        _allServices.addAll(snapshot.docs
            .map((doc) => Service.fromFirestore(doc)));
      });
    } catch (e) {
      print('Error loading more services: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentCity();
    _changeStatusBarColor();
    _fetchProfilePic();
    _searchController.addListener(() {
      _searchServices(_searchController.text);
    });
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });

    _prefetchServices();

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _isLoadingBanners = false; // Initialize banner loading
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentCity() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => userCity = 'Location access denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() => userCity = placemarks.first.locality ?? 'Unknown');
      }
    } catch (e) {
      setState(() => userCity = 'Location error');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: UserTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: UserTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screenWidth * 0.05),
                  bottomRight: Radius.circular(screenWidth * 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: UserTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.04, screenHeight * 0.015, screenWidth * 0.04, screenHeight * 0.012),
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<String>(
                      future: getUserName(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildShimmerForHeader(screenWidth, screenHeight);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${snapshot.data ?? 'User'} 👋',
                              style: TextStyle(
                                color: UserTheme.onPrimaryTextColor,
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.025, vertical: screenHeight * 0.005),
                              decoration: BoxDecoration(
                                color: UserTheme.onPrimaryTextColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: UserTheme.onPrimaryTextColor,
                                    size: screenWidth * 0.035,
                                  ),
                                  SizedBox(width: screenWidth * 0.008),
                                  Text(
                                    userCity,
                                    style: TextStyle(
                                      color: UserTheme.onPrimaryTextColor,
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.09,
                    height: screenWidth * 0.09,
                    decoration: BoxDecoration(
                      color: UserTheme.onPrimaryTextColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.012),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: _profileImageUrl != null
                          ? CircleAvatar(
                        radius: screenWidth * 0.035,
                        backgroundImage: NetworkImage(_profileImageUrl!),
                        backgroundColor: UserTheme.dividerColor,
                      )
                          : Icon(
                        Icons.account_circle,
                        color: UserTheme.onPrimaryTextColor,
                        size: screenWidth * 0.06,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserProfile()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.fromLTRB(
                  screenWidth * 0.05, screenHeight * 0.018, screenWidth * 0.05, screenHeight * 0.018),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: UserTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(screenWidth * 0.037),
                      boxShadow: [
                        BoxShadow(
                          color: UserTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 6),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(
                        color: UserTheme.primaryTextColor,
                        fontSize: screenWidth * 0.04,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for services, providers...',
                        hintStyle: TextStyle(
                          color: UserTheme.secondaryTextColor.withOpacity(0.7),
                          fontSize: screenWidth * 0.035,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.02, right: screenWidth * 0.02),
                          child: Icon(
                            Icons.search,
                            color: UserTheme.primaryColor,
                            size: screenWidth * 0.06,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: UserTheme.secondaryTextColor,
                            size: screenWidth * 0.05,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSuggestions = false;
                            });
                            _searchFocusNode.unfocus();
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.037),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.037),
                          borderSide: BorderSide(
                            color: UserTheme.primaryColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _searchResults = [];
                            _showSuggestions = false;
                          });
                        } else {
                          _searchServices(value);
                        }
                      },
                      onTap: () {
                        if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: child,
                      );
                    },
                    child: (_showSuggestions && _searchController.text.isNotEmpty)
                        ? Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.01),
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.3,
                      ),
                      decoration: BoxDecoration(
                        color: UserTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.037),
                        boxShadow: [
                          BoxShadow(
                            color: UserTheme.shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoadingServices
                          ? _buildShimmerSearchResults(screenWidth, screenHeight)
                          : _searchResults.isEmpty
                          ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Text(
                            'No services found',
                            style: TextStyle(
                              color: UserTheme.secondaryTextColor,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      )
                          : ListView.separated(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          color: UserTheme.dividerColor.withOpacity(0.3),
                          height: 1,
                          indent: screenWidth * 0.05,
                          endIndent: screenWidth * 0.05,
                        ),
                        itemBuilder: (context, index) {
                          final service = _searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.01,
                            ),
                            leading: Container(
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                image: service.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(service.imageUrl),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                                color: service.imageUrl.isEmpty
                                    ? UserTheme.dividerColor
                                    : null,
                              ),
                              child: service.imageUrl.isEmpty
                                  ? Icon(
                                Icons.image,
                                color: UserTheme.secondaryTextColor,
                              )
                                  : null,
                            ),
                            title: Text(
                              service.title,
                              style: TextStyle(
                                color: UserTheme.primaryTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            subtitle: Text(
                              service.category,
                              style: TextStyle(
                                color: UserTheme.secondaryTextColor,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            trailing: Text(
                              '₹${service.price}',
                              style: TextStyle(
                                color: UserTheme.successColor,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            onTap: () {
                              setState(() => _showSuggestions = false);
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceDetailsScreen(
                                    serviceId: service.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: 0),
              height: screenHeight * 0.08,
              padding: EdgeInsets.only(bottom: screenHeight * 0.015),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || _isLoadingCategories) {
                    return _buildShimmerCategoryChips(screenWidth, screenHeight);
                  }

                  List<String> categories = ['All'];
                  categories.addAll(
                      snapshot.data!.docs.map((doc) => doc['name'] as String).toList());

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.05),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = categories[index]);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: categories[index] == selectedCategory
                                  ? UserTheme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              border: Border.all(
                                color: UserTheme.primaryColor,
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.012, horizontal: screenWidth * 0.05),
                            child: Center(
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: categories[index] == selectedCategory
                                      ? UserTheme.onPrimaryTextColor
                                      : UserTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + screenHeight * 0.04),
                  child: Column(
                    children: [
                      _buildSectionHeader('Popular Services'),
                      _buildPopularServices(),
                      _buildSectionHeader('Offer Banners'), // New section header
                      _buildOfferBanner(), // New offer banner widget
                      _buildSectionHeader('Top Rated Providers'),
                      _buildProviders(),
                      _buildSectionHeader('All Categories'),
                      _buildCategories(),
                      SizedBox(height: screenHeight * 0.025),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerForHeader(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.4),
      highlightColor: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth * 0.5,
            height: screenHeight * 0.02,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            width: screenWidth * 0.3,
            height: screenHeight * 0.015,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSearchResults(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => Divider(
          color: Colors.transparent,
          height: 1,
        ),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.01,
            ),
            leading: Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                color: Colors.white,
              ),
            ),
            title: Container(
              width: double.infinity,
              height: screenHeight * 0.018,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              width: screenWidth * 0.3,
              height: screenHeight * 0.014,
              margin: EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: Container(
              width: screenWidth * 0.15,
              height: screenHeight * 0.016,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCategoryChips(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.03),
            child: Container(
              width: screenWidth * 0.2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
              ),
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.012,
                  horizontal: screenWidth * 0.05
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerPopularServices(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.28,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: screenWidth * 0.45,
              margin: EdgeInsets.only(right: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.037),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: screenHeight * 0.15,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth * 0.037),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.037),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth * 0.35,
                          height: screenHeight * 0.018,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.025),
                        Container(
                          width: screenWidth * 0.25,
                          height: screenHeight * 0.016,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Container(
                          width: screenWidth * 0.15,
                          height: screenHeight * 0.014,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerProviders(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.04),
            height: screenWidth * 0.24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.037),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Row(
                children: [
                  Container(
                    width: screenWidth * 0.18,
                    height: screenWidth * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.4,
                          height: screenHeight * 0.018,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Container(
                          width: screenWidth * 0.25,
                          height: screenHeight * 0.014,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Container(
                          width: screenWidth * 0.3,
                          height: screenHeight * 0.012,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCategories(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenHeight * 0.02,
          childAspectRatio: 3 / 4,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth * 0.025),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: Container(
                    width: double.infinity,
                    height: screenHeight * 0.02,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          screenWidth * 0.05, screenHeight * 0.03, screenWidth * 0.05, screenHeight * 0.018),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: UserTheme.primaryColor,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: TextStyle(
                color: UserTheme.primaryColor,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenHeight * 0.28,
      child: StreamBuilder<List<Service>>(
        stream: getServices(selectedCategory),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildShimmerPopularServices(screenWidth, screenHeight);
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Service service = snapshot.data![index];
              return ServiceCard(
                id: service.id,
                title: service.title,
                price: '₹${service.price}',
                imageUrl: service.imageUrl,
                category: service.category,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProviders() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildShimmerProviders(screenWidth, screenHeight);
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final provider = Provider.fromFirestore(snapshot.data!.docs[index]);
            return ProviderCard(
              id: provider.id,
              name: provider.name,
              phoneNumber: provider.phoneNumber,
              profilePicUrl: provider.profilePicUrl,
            );
          },
        );
      },
    );
  }

  Widget _buildCategories() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildShimmerCategories(screenWidth, screenHeight);
        }

        final categories = snapshot.data!.docs
            .map((doc) => {
          'name': doc['name'] as String?,
          'imageUrl': doc['imageUrl'] as String?,
        })
            .toList();

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenHeight * 0.02,
            childAspectRatio: 3 / 4,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final categoryName = category['name'] ?? 'Unknown Category';
            final imageUrl = category['imageUrl'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubcategoriesPage(categoryName: categoryName),
                  ),
                );
              },
              child: GridCategoryCard(
                title: categoryName,
                imagePath: imageUrl,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOfferBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offerbanner').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || _isLoadingBanners) {
          return Container(
            height: screenHeight * 0.25,
            child: _buildShimmerOfferBanner(screenWidth, screenHeight),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: screenHeight * 0.25,
            child: Center(
              child: Text(
                'Error loading banners',
                style: TextStyle(color: UserTheme.errorTextColor),
              ),
            ),
          );
        }

        final banners = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'url': data['url'] ?? data['servicename'] ?? '', // Fallback to servicename if url is missing
            'serviceId': data['serviceId'] ?? '', // Add serviceId from Firestore
          };
        }).toList();

        if (banners.isEmpty) {
          return Container(
            height: screenHeight * 0.25,
            child: Center(
              child: Text(
                'No banners available',
                style: TextStyle(color: UserTheme.secondaryTextColor),
              ),
            ),
          );
        }

        return Container(
          height: screenHeight * 0.25,
          child: CarouselSlider(
            options: CarouselOptions(
              height: screenHeight * 0.25,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              viewportFraction: 0.9,
            ),
            items: banners.map((banner) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      final serviceId = banner['serviceId'] as String;
                      if (serviceId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetailsScreen(serviceId: serviceId),
                          ),
                        );
                      } else {
                        print('No serviceId available for this banner');
                      }
                    },
                    child: Container(
                      width: screenWidth,
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.037),
                        image: DecorationImage(
                          image: NetworkImage(banner['url'] as String),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            print('Image loading error: $exception');
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildShimmerOfferBanner(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: screenHeight * 0.25,
        width: screenWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.037),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  const CategoryChip({
    required this.label,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.012),
        decoration: BoxDecoration(
          color: selected
              ? UserTheme.primaryColor
              : UserTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          border: Border.all(
            color: selected
                ? UserTheme.primaryColor
                : UserTheme.dividerColor,
            width: 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: UserTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? UserTheme.onPrimaryTextColor
                : UserTheme.secondaryTextColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: screenWidth * 0.035,
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String category;

  const ServiceCard({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(serviceId: id),
          ),
        );
      },
      child: Container(
        width: screenWidth * 0.45,
        margin: EdgeInsets.only(right: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: UserTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.037),
          boxShadow: [
            BoxShadow(
              color: UserTheme.shadowColor,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.037)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: UserTheme.dividerColor,
                      child: Icon(
                        Icons.error,
                        color: UserTheme.disabledTextColor,
                      ),
                    );
                  },
                )
                    : Container(
                  color: UserTheme.dividerColor,
                  child: Icon(
                    Icons.image,
                    color: UserTheme.disabledTextColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.037),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                      color: UserTheme.primaryTextColor,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.015),
                  Text(
                    price,
                    style: TextStyle(
                      color: UserTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.037,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: UserTheme.warningColor,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        "4.5",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: UserTheme.secondaryTextColor,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
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

class ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String phoneNumber;
  final String profilePicUrl;

  const ProviderCard({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
  });

  // Declare _navigateToProviderServices before it is used
  void _navigateToProviderServices(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderServicesPage(providerId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        _navigateToProviderServices(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.04),
        decoration: BoxDecoration(
          color: UserTheme.surfaceColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.037),
          boxShadow: [
            BoxShadow(
              color: UserTheme.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  color: UserTheme.dividerColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: profilePicUrl.isNotEmpty
                      ? Image.network(
                    profilePicUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: UserTheme.secondaryTextColor,
                        size: screenWidth * 0.09,
                      );
                    },
                  )
                      : Icon(
                    Icons.person,
                    color: UserTheme.secondaryTextColor,
                    size: screenWidth * 0.09,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                        color: UserTheme.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: UserTheme.primaryColor,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.015),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: UserTheme.warningColor,
                          size: screenWidth * 0.04,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          "4.8",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.032,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          " (120 reviews)",
                          style: TextStyle(
                            color: UserTheme.secondaryTextColor,
                            fontSize: screenWidth * 0.032,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: UserTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: screenWidth * 0.04,
                    color: UserTheme.primaryColor,
                  ),
                  onPressed: () {
                    _navigateToProviderServices(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const GridCategoryCard({
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
        color: UserTheme.surfaceColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.025)),
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: UserTheme.onPrimaryTextColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  color: UserTheme.primaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Service {
  final String id;
  final String title;
  final String category;
  final double price;
  final String imageUrl;

  Service({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      title: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
          ? data['images'][0]
          : '',
    );
  }
}

class Provider {
  final String id;
  final String name;
  final String phoneNumber;
  final String profilePicUrl;

  Provider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
  });

  factory Provider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Provider(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phone'] ?? '',
      profilePicUrl: data['profileImage'] ?? '',
    );
  }
}