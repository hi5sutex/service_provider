import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _updateProfile() async {
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
              profileImageUrl = imageUrl;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile picture updated successfully!")),
            );
          }
        } else {
          throw Exception("Failed to upload image to Cloudinary.");
        }
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading profile picture: $e")),
      );
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
                onTap: _updateProfile,
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
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Address (Area, City, State)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
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
