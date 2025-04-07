import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final String providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String email = "";
  String profileImageUrl = "https://avatar.iran.liara.run/public";
  bool isLoading = true;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchProviderDetails();
  }

  Future<void> _fetchProviderDetails() async {
    try {
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .get();
      var providerData = providerDoc.data() as Map<String, dynamic>;

      setState(() {
        nameController.text = providerData['name'] ?? '';
        phoneController.text = providerData['phone'] ?? '';
        bioController.text = providerData['bio'] ?? '';
        addressController.text = providerData['address']?['string'] ?? '';
        email = providerData['email'] ?? '';
        profileImageUrl = providerData['profileImage'] ?? profileImageUrl;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching provider details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance.collection('providers').doc(providerId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'bio': bioController.text,
        'address': {
          'string': addressController.text,
          'latitude': _latitude,
          'longitude': _longitude,
        },
        'profileImage': profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Location permission denied permanently. Enable it in settings."),
        ));
        return;
      }

      // ignore: deprecated_member_use
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;

      String address = await _getHumanReadableAddress(_latitude!, _longitude!);
      setState(() {
        addressController.text = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Location: $address (Lat: $_latitude, Long: $_longitude)"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: $e")),
      );
    }
  }

  Future<String> _getHumanReadableAddress(double lat, double lon) async {
    final Uri url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? "Unknown Location";
      } else {
        return "Error Fetching Address";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<void> _selectProfileImage() async {
    var profileImagesDoc = await FirebaseFirestore.instance.collection('profileImages').get();
    var defaultImages = profileImagesDoc.docs.map((doc) => doc.data()['url']).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ProviderTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Select Profile Image",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: ProviderTheme.primaryTextColor,
            ),
          ),
          content: Container(
            height: 300,
            width: double.maxFinite,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: defaultImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      profileImageUrl = defaultImages[index];
                    });
                    Navigator.pop(context);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      defaultImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: ProviderTheme.onPrimaryTextColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: ProviderTheme.onPrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: ProviderTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ProviderTheme.secondaryColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ProviderTheme.secondaryColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 70),
                          GestureDetector(
                            onTap: _selectProfileImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        ProviderTheme.primaryColor,
                                        ProviderTheme.secondaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ProviderTheme.secondaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: ProviderTheme.secondaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: ProviderTheme.secondaryColor.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: ProviderTheme.onPrimaryTextColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            nameController.text.isEmpty ? 'Your Name' : nameController.text,
                            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                              color: ProviderTheme.onPrimaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            email.isEmpty ? 'example@example.com' : email,
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: ProviderTheme.onPrimaryTextColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: ProviderTheme.primaryColor,
            elevation: 4,
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: ProviderTheme.secondaryColor)),
            )
                : Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ProviderTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ProviderTheme.shadowColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: "Full Name",
                      icon: Icons.person,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: phoneController,
                      label: "Phone",
                      icon: Icons.phone,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: bioController,
                      label: "Bio",
                      icon: Icons.info,
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: addressController,
                            label: "Address (Area, City, State)",
                            icon: Icons.location_city,
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: _getCurrentLocation,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ProviderTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ProviderTheme.secondaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: ProviderTheme.onPrimaryTextColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          backgroundColor: ProviderTheme.defaultButtonColor,
                          foregroundColor: ProviderTheme.onPrimaryTextColor,
                        ),
                        child: Text(
                          "Save Changes",
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ProviderTheme.secondaryColor),
        filled: true,
        fillColor: ProviderTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProviderTheme.dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ProviderTheme.secondaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: ProviderTheme.secondaryTextColor),
      ),
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: ProviderTheme.primaryTextColor,
      ),
    );
  }
}