import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:service_provider/User%20Panel/UserOtpPage.dart';
import 'package:service_provider/User%20Panel/edit_profile.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';
import 'package:service_provider/User%20Panel/FavoriteServicesPage.dart'; // New import

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

        String uploadUrl =
            "https://api.cloudinary.com/v1_1/dpcjw0g5c/image/upload";
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

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: UserTheme.primaryColor,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout,
                  size: screenWidth * 0.12,
                  color: UserTheme.onPrimaryTextColor,
                ),
                SizedBox(height: screenWidth * 0.04),
                Text(
                  'Are you sure?',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: UserTheme.onPrimaryTextColor,
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  'You will be logged out of your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: UserTheme.onPrimaryTextColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: screenWidth * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UserTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenWidth * 0.025),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: UserTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UserTheme.errorTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenWidth * 0.025),
                      ),
                      onPressed: () async {
                        await _auth.signOut();
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: UserTheme.onPrimaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: UserTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: UserTheme.onPrimaryTextColor,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _profileDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: UserTheme.onPrimaryTextColor,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(
                  color: UserTheme.onPrimaryTextColor,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: UserTheme.primaryColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(screenWidth * 0.075),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadProfilePicture,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: UserTheme.onPrimaryTextColor,
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: screenWidth * 0.12,
                                  backgroundColor: UserTheme.dividerColor,
                                  backgroundImage: _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                                  child: _profileImageUrl == null
                                      ? Icon(
                                    Icons.person,
                                    size: screenWidth * 0.12,
                                    color: UserTheme.secondaryTextColor,
                                  )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.01),
                                  decoration: BoxDecoration(
                                    color: UserTheme.onPrimaryTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: screenWidth * 0.04,
                                    color: UserTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          _userName ?? 'Hello, User',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: UserTheme.onPrimaryTextColor,
                          ),
                        ),
                        Text(
                          _phoneNumber != null
                              ? '+91 $_phoneNumber'
                              : 'Lagos, Nigeria',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: UserTheme.onPrimaryTextColor.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: UserTheme.surfaceColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.075),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.person_outline,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.045,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditUserProfile()),
                          );
                        },
                      ),
                      Divider(color: UserTheme.dividerColor),
                      ListTile(
                        leading: Icon(
                          Icons.lock_outline,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.045,
                        ),
                        onTap: () {},
                      ),
                      Divider(color: UserTheme.dividerColor),
                      ListTile(
                        leading: Icon(
                          Icons.dark_mode_outlined,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {},
                          activeColor: UserTheme.primaryColor,
                        ),
                      ),
                      Divider(color: UserTheme.dividerColor),
                      ListTile(
                        leading: Icon(
                          Icons.favorite_border,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'Favorite Services',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.045,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FavoriteServicesPage()),
                          );
                        },
                      ),
                      Divider(color: UserTheme.dividerColor),
                      ListTile(
                        leading: Icon(
                          Icons.vpn_key,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'View OTP',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.045,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserOtpPage()),
                          );
                        },
                      ),
                      Divider(color: UserTheme.dividerColor),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: UserTheme.primaryColor,
                          size: screenWidth * 0.06,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: UserTheme.primaryTextColor,
                          ),
                        ),
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}