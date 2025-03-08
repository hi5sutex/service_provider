import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider%20Panel/screens/work_proof.dart';
import 'dart:math';

class OtpBookingPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const OtpBookingPage({
    required this.bookingId,
    required this.bookingData,
    Key? key,
  }) : super(key: key);

  @override
  _OtpBookingPageState createState() => _OtpBookingPageState();
}

class _OtpBookingPageState extends State<OtpBookingPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifyingOtp = false;
  String? _generatedOtp;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndGenerateOtp();
  }

  // Generate a random 6-digit OTP
  String _generateOtp() {
    return (100000 + Random().nextInt(900000)).toString(); // 100000-999999
  }

  // Fetch userId from booking and generate OTP
  Future<void> _fetchUserIdAndGenerateOtp() async {
    try {
      // Fetch booking document to get userId
      DocumentSnapshot bookingDoc =
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      if (!bookingDoc.exists || bookingDoc['userId'] == null) {
        _showError('Booking or user ID not found');
        return;
      }

      _userId = bookingDoc['userId'] as String;
      print('Fetched userId: $_userId');

      // Generate and store OTP
      _generatedOtp = _generateOtp();
      print('Generated OTP: $_generatedOtp for booking: ${widget.bookingId}');

      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'otp': _generatedOtp,
        'otpGeneratedAt': Timestamp.now(),
        'otpStatus': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to user')),
      );
    } catch (e) {
      print('Error generating OTP: $e');
      _showError('Error generating OTP: $e');
    }
  }

  // Verify OTP entered by provider
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      DocumentSnapshot bookingDoc =
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      if (!bookingDoc.exists || bookingDoc['otp'] == null) {
        _showError('OTP not found for this booking');
        setState(() {
          _isVerifyingOtp = false;
        });
        return;
      }

      String storedOtp = bookingDoc['otp'] as String;

      if (_otpController.text == storedOtp) {
        await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
          'otpStatus': 'verified',
          'otpVerifiedAt': Timestamp.now(),
          'status': 'Completed', // Update booking status
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkProofPage(
              bookingId: widget.bookingId,
              bookingData: widget.bookingData,
            ),
          ),
        );
      } else {
        _showError('Invalid OTP');
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      _showError('Error verifying OTP: $e');
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        backgroundColor: const Color(0xFF060644),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ask the user ($_userId) for the OTP displayed in their app',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isVerifyingOtp ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF060644),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isVerifyingOtp
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify OTP', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}