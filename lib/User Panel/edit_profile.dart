import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditUserProfile extends StatefulWidget {
  @override
  _EditUserProfileState createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _auth = FirebaseAuth.instance;
  final picker = ImagePicker();

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
        profileImageUrl = userData['profileImage'] ?? "https://avatar.iran.liara.run/public";
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        isLoading = false;
      });
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
    final Uri url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _getCurrentLocation,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: email),
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email (Uneditable)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: "Address (Area, City, State)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.location_on, color: Colors.white),
                    onPressed: _getCurrentLocation,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
