import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:service_provider/User%20Panel/Usertheme.dart';

class EditUserProfile extends StatefulWidget {
  @override
  _EditUserProfileState createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String email = "";
  String profileImageUrl = "https://avatar.iran.liara.run/public";
  bool isLoading = true;
  bool isSaving = false;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        nameController.text = userData['name'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        bioController.text = userData['bio'] ?? '';
        addressController.text = userData['address']?['string'] ?? '';
        email = userData['email'] ?? '';
        profileImageUrl =
            userData['profileImage'] ?? "https://avatar.iran.liara.run/public";
        isLoading = false;
      });
    } catch (e) {
      _showSnackBar("Error fetching user details");
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permission denied permanently");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;

      String address = await _getHumanReadableAddress(_latitude!, _longitude!);
      setState(() => addressController.text = address);
    } catch (e) {
      _showSnackBar("Error fetching location");
    }
  }

  Future<String> _getHumanReadableAddress(double lat, double lon) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? "Unknown Location";
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
    return "Error fetching address";
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'bio': bioController.text,
        'address': {
          'string': addressController.text,
          'coordinates': _latitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _showSnackBar("Profile updated successfully!");
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Error updating profile");
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: UserTheme.primaryColor, // Matches #060644 (Primary)
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.08,
            pinned: true,
            // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Edit Profile",
                style: TextStyle(
                  color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screenWidth * 0.075),
                  bottomRight: Radius.circular(screenWidth * 0.075),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        UserTheme.primaryColor, // Matches #060644 (Primary)
                        Color(0xFF2A2A6F), // Retain the gradient end color
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                size: screenWidth * 0.06,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                  size: screenWidth * 0.06,
                ),
                onPressed: _saveChanges,
              ),
            ],
          ),
          SliverFillRemaining(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: UserTheme.shadowColor, // Matches #00000029 (Shadow)
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundImage:
                              NetworkImage(profileImageUrl),
                            ),
                          ),
                          Positioned(
                            bottom: screenWidth * 0.01,
                            right: screenWidth * 0.01,
                            child: Container(
                              width: screenWidth * 0.08,
                              height: screenWidth * 0.08,
                              decoration: BoxDecoration(
                                color: UserTheme.primaryColor, // Matches #060644 (Primary)
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                                  size: screenWidth * 0.04,
                                ),
                                onPressed: () {
                                  // Handle image picker
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Form Fields
                    _buildTextField(
                      controller: nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      validator: (value) => value?.isEmpty ?? true
                          ? "Name is required"
                          : null,
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    _buildTextField(
                      controller: TextEditingController(text: email),
                      label: "Email",
                      icon: Icons.email_outlined,
                      readOnly: true,
                      filled: true,
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    _buildTextField(
                      controller: phoneController,
                      label: "Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    _buildTextField(
                      controller: bioController,
                      label: "Bio",
                      icon: Icons.edit_note_outlined,
                      minLines: 1,
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    _buildTextField(
                      controller: addressController,
                      label: "Address",
                      icon: Icons.location_on_outlined,
                      suffix: IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: UserTheme.primaryColor, // Matches #060644 (Primary)
                          size: screenWidth * 0.06,
                        ),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveChanges,
                        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                          // Background and text colors are set by ProviderTheme.elevatedButtonTheme
                          padding: WidgetStateProperty.all(
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                          ),
                        ),
                        child: isSaving
                            ? SizedBox(
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                            ),
                          ),
                        )
                            : Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
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
    bool filled = false,
    int? minLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      minLines: minLines ?? 1,
      maxLines: null,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        // Label style, icon color, borders, etc., are set by ProviderTheme.inputDecorationTheme
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: filled,
        fillColor: filled ? UserTheme.dividerColor : null, // Matches #D1D9E1 (Divider)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
    );
  }
}