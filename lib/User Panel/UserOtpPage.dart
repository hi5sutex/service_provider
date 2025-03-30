import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';

class UserOtpPage extends StatelessWidget {
  const UserOtpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
      appBar: AppBar(
        title: const Text('Your OTP'),
        backgroundColor: UserTheme.primaryColor, // Matches #060644 (Primary)
        titleTextStyle: TextStyle(
          color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('otpStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: UserTheme.primaryColor, // Matches #060644 (Primary)
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No active bookings with OTP available',
                style: TextStyle(
                  fontSize: 16,
                  color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
            );
          }

          final bookingDoc = snapshot.data!.docs.first;
          final String otp = bookingDoc['otp'] as String? ?? 'N/A';
          final String bookingId = bookingDoc.id; // Use document ID as bookingId

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Your OTP for Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Booking ID: $bookingId',
                  style: TextStyle(
                    fontSize: 16,
                    color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: UserTheme.dividerColor, // Matches #D1D9E1 (Divider)
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    otp,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share this OTP with your service provider to complete the booking.',
                  style: TextStyle(
                    fontSize: 16,
                    color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}