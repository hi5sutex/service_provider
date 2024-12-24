import 'package:flutter/material.dart';

class ProviderHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Provider Dashboard',
          // style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Overview
            Text(
              'Dashboard Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDashboardCard(
                  title: 'Total Bookings',
                  value: '150',
                  color: Colors.blue.shade100,
                ),
                _buildDashboardCard(
                  title: 'Earnings',
                  value: '\$3,450',
                  color: Colors.green.shade100,
                ),
                _buildDashboardCard(
                  title: 'Ratings',
                  value: '4.8',
                  color: Colors.orange.shade100,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionCard(
                  icon: Icons.add,
                  label: 'Add Service',
                  onTap: () {
                    // Navigate to Add Service screen
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.edit,
                  label: 'Edit Services',
                  onTap: () {
                    // Navigate to Edit Services screen
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.analytics,
                  label: 'Performance',
                  onTap: () {
                    // Navigate to Performance Analytics screen
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // Recent Bookings
            Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: recentBookings.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.book_online, color: Colors.blue),
                      ),
                      title: Text(recentBookings[index]['clientName']!),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recentBookings[index]['service']!,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            recentBookings[index]['date']!,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Text(
                        recentBookings[index]['status']!,
                        style: TextStyle(
                          color: recentBookings[index]['status']! == 'Completed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required String title, required String value, required Color color}) {
    return Expanded(
      child: Container(
        height: 100,
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  final List<Map<String, String>> recentBookings = [
    {
      'clientName': 'Alice Smith',
      'service': 'Home Cleaning',
      'date': 'Dec 23, 2024',
      'status': 'Completed',
    },
    {
      'clientName': 'John Doe',
      'service': 'Plumbing Repair',
      'date': 'Dec 22, 2024',
      'status': 'Pending',
    },
  ];
}
