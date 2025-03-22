import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:service_provider/User%20Panel/UserOtpPage.dart';
import 'package:service_provider/User%20Panel/edit_profile.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/theme.dart';

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
          backgroundColor: AppTheme.primaryColorCustom, // Dark Blue
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout,
                    size: screenWidth * 0.12, color: AppTheme.secondaryColorCustom),
                SizedBox(height: screenWidth * 0.04),
                Text(
                  'Are you sure?',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColorCustom,
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  'You will be logged out of your account.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: AppTheme.secondaryColorCustom.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColorCustom,
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
                          color: AppTheme.primaryColorCustom,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
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
                          color: AppTheme.secondaryColorCustom,
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
      backgroundColor: AppTheme.primaryColorCustom, // Dark Blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.secondaryColorCustom, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _profileDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                  color: AppTheme.secondaryColorCustom),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(
                    color: AppTheme.secondaryColorCustom,
                    fontSize: screenWidth * 0.045),
              ),
            );
          }

          return Column(
            children: [
              // Top Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColorCustom,
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
                                    color: AppTheme.secondaryColorCustom,
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: screenWidth * 0.12,
                                  backgroundColor: AppTheme.greyLight,
                                  backgroundImage: _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                                  child: _profileImageUrl == null
                                      ? Icon(Icons.person,
                                      size: screenWidth * 0.12,
                                      color: Colors.grey[400])
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.01),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColorCustom,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt,
                                      size: screenWidth * 0.04,
                                      color: AppTheme.primaryColorCustom),
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
                            color: AppTheme.secondaryColorCustom,
                          ),
                        ),
                        Text(
                          _phoneNumber != null
                              ? '+91 $_phoneNumber'
                              : 'Lagos, Nigeria',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color:
                            AppTheme.secondaryColorCustom.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom White Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColorCustom,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.075),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_outline,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.06),
                        title: Text('Edit Profile',
                            style:
                            TextStyle(fontSize: screenWidth * 0.045)),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.045),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditUserProfile()),
                          );
                        },
                      ),
                      Divider(color: AppTheme.greyLight),
                      ListTile(
                        leading: Icon(Icons.lock_outline,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.06),
                        title: Text('Change Password',
                            style:
                            TextStyle(fontSize: screenWidth * 0.045)),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.045),
                        onTap: () {},
                      ),
                      Divider(color: AppTheme.greyLight),
                      ListTile(
                        leading: Icon(Icons.dark_mode_outlined,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.06),
                        title: Text('Dark Mode',
                            style:
                            TextStyle(fontSize: screenWidth * 0.045)),
                        trailing: Switch(
                          value: true,
                          onChanged: (value) {},
                          activeColor: AppTheme.primaryColorCustom,
                        ),
                      ),
                      Divider(color: AppTheme.greyLight),
                      ListTile(
                        leading: Icon(Icons.vpn_key,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.06),
                        title: Text('View OTP',
                            style:
                            TextStyle(fontSize: screenWidth * 0.045)),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.045),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserOtpPage()),
                          );
                        },
                      ),
                      Divider(color: AppTheme.greyLight),
                      ListTile(
                        leading: Icon(Icons.logout,
                            color: AppTheme.primaryColorCustom,
                            size: screenWidth * 0.06),
                        title: Text('Logout',
                            style:
                            TextStyle(fontSize: screenWidth * 0.045)),
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