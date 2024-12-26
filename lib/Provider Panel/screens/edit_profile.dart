import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final String providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Controllers for text fields
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  String email = "";
  String profileImageUrl =
      "https://avatar.iran.liara.run/public"; // Default profile image
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
        profileImageUrl = providerData['profileImage'] ??
            "https://avatar.iran.liara.run/public";
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

  // Future<String> _getHumanReadableAddress(double lat, double long) async {
  //   const String apiKey = "YOUR_GOOGLE_GEOCODING_API_KEY"; // Replace with your key
  //   final Uri url = Uri.parse(
  //       "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=$apiKey");
  //
  //   try {
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> data = jsonDecode(response.body);
  //
  //       if (data['status'] == "OK" && data['results'].isNotEmpty) {
  //         return data['results'][0]['formatted_address'];
  //       } else {
  //         return "Unknown Location";
  //       }
  //     } else {
  //       return "Error Fetching Address";
  //     }
  //   } catch (e) {
  //     return "Error Fetching Address: $e";
  //   }
  // }

  Future<String> _getHumanReadableAddress(double lat, double lon) async {
    // final Uri url = Uri.parse(
    //     "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon");
    //
    // try {
    //   final response = await http.get(url);
    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     return data['display_name'] ?? "Unknown Location";
    //   } else {
    //     return "Error Fetching Address";
    //   }
    // } catch (e) {
    //   return "Error: $e";
    // }
    return "";
  }


  Future<void> _selectProfileImage() async {
    // Fetch default profile images from Firebase
    var profileImagesDoc = await FirebaseFirestore.instance.collection('profileImages').get();
    var defaultImages = profileImagesDoc.docs.map((doc) => doc.data()['url']).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Profile Image"),
          content: Container(
            height: 300,
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
                  child: Image.network(
                    defaultImages[index],
                    fit: BoxFit.cover,
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
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: _selectProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Full Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Email (Non-editable)
            TextField(
              controller: TextEditingController(text: email),
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email (Uneditable)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Phone
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Bio
            TextField(
              controller: bioController,
              decoration: InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Address with Location Icon
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

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
