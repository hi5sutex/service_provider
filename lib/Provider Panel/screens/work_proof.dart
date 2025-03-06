import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkProofPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const WorkProofPage({
    required this.bookingId,
    required this.bookingData,
    Key? key,
  }) : super(key: key);

  @override
  _WorkProofPageState createState() => _WorkProofPageState();
}

class _WorkProofPageState extends State<WorkProofPage> {
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Cloudinary credentials
  final String cloudName = "dpcjw0g5c";
  final String apiKey = "848663135589872";
  final String apiSecret = "4PNyID2iI8vwVnLVFb3V7dHIkls";
  final String uploadPreset = "flutter_unsigned_upload";

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<String?> _uploadToCloudinary(File image) async {
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['upload_preset'] = uploadPreset
      ..fields['api_key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'];
      } else {
        print('Upload failed for image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _submitProof() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Upload all images to Cloudinary
    List<String> imageUrls = [];
    for (File image in _images) {
      final imageUrl = await _uploadToCloudinary(image);
      if (imageUrl != null) {
        imageUrls.add(imageUrl);
      } else {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload one or more images'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Get provider ID
    String providerId = FirebaseAuth.instance.currentUser!.uid;

    // Update Firestore bookings collection
    await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
      'proofOfWork': FieldValue.arrayUnion(imageUrls),
      'status': 'Completed',
      'completedAt': Timestamp.now(),
    });

    // Fetch and update the earnings record
    DocumentReference earningsDocRef = FirebaseFirestore.instance
        .collection('earnings')
        .doc(providerId)
        .collection('records')
        .doc(widget.bookingId);

    DocumentSnapshot earningsDoc = await earningsDocRef.get();
    if (earningsDoc.exists) {
      // Update existing earnings record
      await earningsDocRef.update({
        'earningStatus': 'Completed',
        'completedAt': Timestamp.now(), // Optional: update completion timestamp
      });
    } else {
      // If no earnings record exists, create one (optional fallback)
      dynamic paymentAmount = widget.bookingData['paymentAmount'] ?? 0;
      num amount = paymentAmount is String ? int.tryParse(paymentAmount) ?? 0 : paymentAmount is num ? paymentAmount : 0;

      await earningsDocRef.set({
        'bookingId': widget.bookingId,
        'providerId': providerId,
        'paymentId': widget.bookingData['paymentMode'] == 'COD' ? 'COD' : 'unknown', // Adjust based on your data
        'serviceAmount': amount, // Adjust fields as per your structure
        'taxAmount': (amount * 0.11).round(), // Example tax calculation (11%)
        'platformFee': (amount * 0.05).round(), // Example platform fee (5%)
        'paymentAmount': amount - ((amount * 0.11) + (amount * 0.05)).round(), // Net amount
        'earningStatus': 'Completed',
        'paymentAt': Timestamp.now(),
        'completedAt': Timestamp.now(),
      });
    }

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proof submitted and booking completed')),
    );
    Navigator.pop(context); // Back to LiveTrackingPage
    Navigator.pop(context); // Back to booking list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Proof of Work'),
        backgroundColor: const Color(0xFF060644),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _images.isEmpty
                  ? Container(
                color: Colors.grey[200],
                child: const Center(child: Text('No images selected')),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.file(_images[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF060644),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImagesFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF060644),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF060644),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Proof', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}