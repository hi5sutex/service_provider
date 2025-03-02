import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> checkAndUpdateExpiredBookings(String? providerId) async {
  final now = DateTime.now();
  final bookingsSnapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('providerId', isEqualTo: providerId)
      .where('status', whereIn: ['Pending', 'Confirmed'])
      .get();

  final batch = FirebaseFirestore.instance.batch();
  bool hasBatchOperations = false;

  for (var doc in bookingsSnapshot.docs) {
    final bookingData = doc.data();
    final serviceDate = (bookingData['serviceDate'] as Timestamp).toDate();
    if (serviceDate.isBefore(now)) {
      batch.update(doc.reference, {
        'status': 'Cancelled',
        'cancelReason': 'Expired booking',
        'cancelledAt': Timestamp.now(),
      });
      hasBatchOperations = true;
    }
  }

  if (hasBatchOperations) {
    await batch.commit();
  }
}

Stream<List<Map<String, dynamic>>> fetchBookings(String status, String providerId) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: status)
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();
    final bookings = snapshot.docs
        .map((doc) => {...doc.data(), 'bId': doc.id})
        .toList();

    if (status == 'Pending' || status == 'Confirmed') {
      bookings.sort((a, b) {
        DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
        DateTime bDate = (b['serviceDate'] as Timestamp).toDate();
        DateTime aJustDate = DateTime(aDate.year, aDate.month, aDate.day);
        DateTime bJustDate = DateTime(bDate.year, bDate.month, bDate.day);
        DateTime nowJustDate = DateTime(now.year, now.month, now.day);

        int aDayDiff = aJustDate.difference(nowJustDate).inDays;
        int bDayDiff = bJustDate.difference(nowJustDate).inDays;

        if (aDayDiff < 0 && bDayDiff >= 0) return 1;
        if (bDayDiff < 0 && aDayDiff >= 0) return -1;
        if (aDayDiff != bDayDiff) return aDayDiff.abs() - bDayDiff.abs();

        return aDate.compareTo(bDate);
      });
    } else {
      bookings.sort((a, b) {
        DateTime aDate = (a['serviceDate'] as Timestamp).toDate();
        DateTime bDate = (b['serviceDate'] as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });
    }

    return bookings;
  });
}