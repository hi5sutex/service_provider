import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:service_provider/User%20Panel/edit_profile.dart';
import 'package:service_provider/User%20Panel/user_setting.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final picker = ImagePicker();

  String? _profileImageUrl;
  String? _userName;
  String? _phoneNumber;

  late Future<void> _profileDetailsFuture;

  @override
  void initState() {
    super.initState();
    _profileDetailsFuture = _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _profileImageUrl = userDoc['profileImage'] as String?;
          _userName = userDoc['name'] as String?;
          _phoneNumber = userDoc['phone'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching profile details: $e');
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        String filePath = pickedFile.path;

        String uploadUrl = "https://api.cloudinary.com/v1_1/dpcjw0g5c/image/upload";
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(filePath),
          "upload_preset": "flutter_unsigned_upload",
        });

        Dio dio = Dio();
        Response response = await dio.post(uploadUrl, data: formData);

        if (response.statusCode == 200) {
          String imageUrl = response.data['secure_url'];
          User? user = _auth.currentUser;

          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'profileImage': imageUrl});

            setState(() {
              _profileImageUrl = imageUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<void>(
        future: _profileDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _uploadProfilePicture,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                    child: _profileImageUrl == null
                        ? Icon(Icons.camera_alt, color: Colors.grey)
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _userName ?? 'Hello, User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _phoneNumber != null ? '+91 $_phoneNumber' : 'Your Phone Number',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit Profile'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditUserProfile(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.settings, color: Colors.blue),
                  title: Text('Settings'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () async {
                    await _logout(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
