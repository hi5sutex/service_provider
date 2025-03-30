import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';
// import 'Usertheme.dart'; // Import ProviderTheme

class BookingTrackingPage extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final String serviceName;

  const BookingTrackingPage({
    required this.bookingId,
    required this.bookingData,
    required this.serviceName,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not specified';
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  List<Map<String, dynamic>> _getTimelineStages(String status) {
    List<Map<String, dynamic>> stages = [];

    String bookingDate = _formatTimestamp(bookingData['bookingDate'] as Timestamp?);
    String confirmedAt = _formatTimestamp(bookingData['confirmedAt'] as Timestamp?);
    String ongoingAt = _formatTimestamp(bookingData['ongoingAt'] as Timestamp?);
    String completedAt = _formatTimestamp(bookingData['completedAt'] as Timestamp?);
    String cancelledAt = _formatTimestamp(bookingData['cancelledAt'] as Timestamp?);

    switch (status) {
      case 'Pending':
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking Request',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': false,
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': 'Not specified',
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': false,
        });
        stages.add({
          'title': 'Booking Completed',
          'description': 'Your Booking has been completed',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Completed)
          'isActive': false,
        });
        break;

      case 'Confirmed':
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': confirmedAt,
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': 'Not specified',
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': false,
        });
        stages.add({
          'title': 'Booking Completed',
          'description': 'Your Booking has been completed',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Completed)
          'isActive': false,
        });
        break;

      case 'Ongoing':
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': confirmedAt,
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': ongoingAt,
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Completed',
          'description': 'Your Booking has been completed',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Completed)
          'isActive': false,
        });
        break;

      case 'Completed':
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': confirmedAt,
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': ongoingAt,
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Completed',
          'description': 'Your Booking has been completed',
          'date': completedAt,
          'color': UserTheme.completedColor, // Matches #388E3C (Completed)
          'isActive': true,
        });
        break;

      case 'Cancelled':
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': confirmedAt,
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': confirmedAt != 'Not specified',
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': ongoingAt,
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': ongoingAt != 'Not specified',
        });
        stages.add({
          'title': 'Booking Cancelled',
          'description': 'Your Booking has been cancelled',
          'date': cancelledAt,
          'color': UserTheme.canceledColor, // Matches #D32F2F (Cancelled)
          'isActive': true,
        });
        break;

      default:
        stages.add({
          'title': 'Booking Placed',
          'description': 'We have received your Booking',
          'date': bookingDate,
          'color': UserTheme.pendingColor, // Matches #607D8B (Pending)
          'isActive': true,
        });
        stages.add({
          'title': 'Booking Confirmed',
          'description': 'We have been confirmed your Booking',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Confirmed/Completed)
          'isActive': false,
        });
        stages.add({
          'title': 'Booking Processed',
          'description': 'Provider is On the Way...',
          'date': 'Not specified',
          'color': UserTheme.ongoingColor, // Matches #7B1FA2 (Ongoing)
          'isActive': false,
        });
        stages.add({
          'title': 'Booking Completed',
          'description': 'Your Booking has been completed',
          'date': 'Not specified',
          'color': UserTheme.completedColor, // Matches #388E3C (Completed)
          'isActive': false,
        });
    }

    return stages;
  }

  @override
  Widget build(BuildContext context) {
    String status = bookingData['status'] ?? 'Pending';
    String orderId = bookingData['id'] ?? 'Unknown Booking';
    String bookingDate = _formatTimestamp(bookingData['bookingDate'] as Timestamp?);
    String serviceDate = _formatTimestamp(bookingData['serviceDate'] as Timestamp?);
    String serviceTime = bookingData['serviceTime'] ?? 'Not specified';
    String paymentAmount = '\$${bookingData['paymentAmount'] ?? '0'}';

    List<Map<String, dynamic>> timelineStages = _getTimelineStages(status);

    return Scaffold(
      // Background color is set by ProviderTheme.scaffoldBackgroundColor (#F5F7FA)
      appBar: AppBar(
        // Background color is set by ProviderTheme.appBarTheme (Primary #060644)
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Bookings',
          style: TextStyle(
            color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order # $orderId',
                            style: TextStyle(
                              fontSize: 14,
                              color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: timelineStages.last['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: timelineStages.last['color'], // Matches the stage color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildDetailRow(Icons.calendar_today, 'Booking Date', bookingDate),
                      _buildDetailRow(Icons.calendar_today, 'Service Date', serviceDate),
                      _buildDetailRow(Icons.access_time, 'Service Time', serviceTime),
                      _buildDetailRow(Icons.attach_money, 'Total Amount', paymentAmount),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.star, color: UserTheme.warningColor, size: 16), // Matches #FBC02D (Warning)
                          Icon(Icons.star, color: UserTheme.warningColor, size: 16),
                          Icon(Icons.star, color: UserTheme.warningColor, size: 16),
                          Icon(Icons.star, color: UserTheme.warningColor, size: 16),
                          Icon(Icons.star, color: UserTheme.warningColor, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Track Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                ),
              ),
              SizedBox(height: 16),
              _buildOrderTimeline(timelineStages),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contacting support...')),
                      );
                    },
                    style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                      // Background and text colors are set by ProviderTheme.elevatedButtonTheme
                      // (Default Button #060644, On Primary Text #FFFFFF)
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: Text(
                      'Contact Support',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing invoice...')),
                      );
                    },
                    style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                      // Background and text colors are set by ProviderTheme.elevatedButtonTheme
                      // (Default Button #060644, On Primary Text #FFFFFF)
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: Text(
                      'View Invoice',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: UserTheme.primaryColor, // Matches #060644 (Primary)
          ),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(List<Map<String, dynamic>> timelineStages) {
    return Container(
      decoration: BoxDecoration(
        color: UserTheme.surfaceColor, // Matches #FFFFFF (Surface)
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: UserTheme.shadowColor, // Matches #00000029 (Shadow)
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: timelineStages.map((stage) {
          final index = timelineStages.indexOf(stage);
          final isActive = stage['isActive'];
          final color = isActive ? stage['color'] : UserTheme.disabledTextColor; // Matches #B0B8C4 (Disabled Text)
          final isLast = index == timelineStages.length - 1;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: Icon(
                        isActive ? Icons.check : Icons.circle,
                        color: UserTheme.onPrimaryTextColor, // Matches #FFFFFF (On Primary Text)
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 60,
                        color: isActive ? color : UserTheme.disabledTextColor, // Matches #B0B8C4 (Disabled Text)
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? color
                              : UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        stage['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: UserTheme.secondaryTextColor, // Matches #6B7280 (Secondary Text)
                        ),
                      ),
                      if (stage['date'] != 'Not specified') ...[
                        SizedBox(height: 4),
                        Text(
                          stage['date'],
                          style: TextStyle(
                            fontSize: 14,
                            color: UserTheme.primaryTextColor, // Matches #060644 (Primary Text)
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}