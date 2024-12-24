import 'package:flutter/material.dart';

class ProviderBooking extends StatefulWidget {
  @override
  _ProviderBookingState createState() => _ProviderBookingState();
}

class _ProviderBookingState extends State<ProviderBooking> {
  String activeTab = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
      ),
      body: Column(
        children: [
          // Booking Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildTabButton('Pending', 'pending'),
                _buildTabButton('Ongoing', 'ongoing'),
                _buildTabButton('Completed', 'completed'),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Booking List
          Expanded(
            child: _buildBookingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = tab;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activeTab == tab ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: activeTab == tab ? Colors.blue : Colors.grey.shade600,
              fontWeight: activeTab == tab ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    if (activeTab == 'pending') {
      return _buildPendingBookings();
    } else if (activeTab == 'ongoing') {
      return _buildOngoingBookings();
    } else {
      return _buildCompletedBookings();
    }
  }

  Widget _buildPendingBookings() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildBookingCard(
          serviceName: 'House Cleaning',
          clientName: 'John Doe',
          date: 'Today, 2:00 PM - 4:00 PM',
          status: 'Pending',
          statusColor: Colors.orange,
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOngoingBookings() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildBookingCard(
          serviceName: 'AC Repair',
          clientName: 'Sarah Smith',
          date: '123 Main St, New York',
          status: 'In Progress',
          statusColor: Colors.blue,
          actions: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Complete Service'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedBookings() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 1,
      itemBuilder: (context, index) {
        return _buildBookingCard(
          serviceName: 'Plumbing Service',
          clientName: 'Mike Johnson',
          date: '\$120.00',
          status: 'Completed',
          statusColor: Colors.green,
          actions: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.yellow.shade600),
                const SizedBox(width: 4),
                const Text('4.5'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard({
    required String serviceName,
    required String clientName,
    required String date,
    required String status,
    required Color statusColor,
    List<Widget>? actions,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150'), // Placeholder image
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(clientName, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Date and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: actions?.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: action,
                    );
                  }).toList() ?? [],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
