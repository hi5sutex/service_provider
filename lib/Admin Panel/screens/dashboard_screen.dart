import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/payments_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/users_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/services_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/manage_categories.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // Custom color palette
  static const List<Color> chartColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
  ];

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final providersSnapshot = await FirebaseFirestore.instance.collection('providers').get();
    final servicesSnapshot = await FirebaseFirestore.instance.collection('services').get();
    final pendingServicesSnapshot = await FirebaseFirestore.instance.collection('pending_services').get();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final earningsSnapshot = await FirebaseFirestore.instance.collection('earnings').get();
    final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();

    List<Map<String, dynamic>> allEarningsRecords = [];
    for (var providerDoc in earningsSnapshot.docs) {
      final recordsSnapshot = await providerDoc.reference.collection('records').get();
      allEarningsRecords.addAll(recordsSnapshot.docs.map((doc) => doc.data()));
    }

    List<Map<String, dynamic>> processGrowthData(List<QueryDocumentSnapshot> docs, String dateField) {
      final Map<String, int> countByDate = {};
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey(dateField)) {
          final timestamp = data[dateField];
          if (timestamp is Timestamp) {
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
                .toIso8601String()
                .substring(0, 10);
            countByDate[date] = (countByDate[date] ?? 0) + 1;
          }
        }
      }
      final sortedDates = countByDate.keys.toList()..sort();
      int cumulative = 0;
      return sortedDates.map((date) {
        cumulative += countByDate[date]!;
        return {'date': date, 'count': cumulative};
      }).toList();
    }

    Map<String, int> processCategoryData(List<QueryDocumentSnapshot> docs, String categoryField) {
      final Map<String, int> countByCategory = {};
      for (var doc in docs) {
        final category = doc[categoryField] as String? ?? 'Uncategorized';
        countByCategory[category] = (countByCategory[category] ?? 0) + 1;
      }
      return countByCategory;
    }

    List<Map<String, dynamic>> processTopServices(
        List<QueryDocumentSnapshot> bookingDocs, List<QueryDocumentSnapshot> serviceDocs) {
      final Map<String, int> bookingsByService = {};
      for (var doc in bookingDocs) {
        final serviceId = doc['serviceId'] as String;
        bookingsByService[serviceId] = (bookingsByService[serviceId] ?? 0) + 1;
      }
      final serviceNames = {for (var doc in serviceDocs) doc.id: doc['name'] as String? ?? 'Unknown'};
      final sortedServices = bookingsByService.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sortedServices.take(5).map((entry) => {
        'serviceId': entry.key,
        'name': serviceNames[entry.key] ?? 'Unknown',
        'bookings': entry.value,
      }).toList();
    }

    Map<String, int> processBookingStatuses(List<QueryDocumentSnapshot> docs) {
      final Map<String, int> countByStatus = {};
      for (var doc in docs) {
        final status = doc['status'] as String? ?? 'Unknown';
        countByStatus[status] = (countByStatus[status] ?? 0) + 1;
      }
      return countByStatus;
    }

    Map<String, double> processEarningsStatus(List<Map<String, dynamic>> records) {
      final Map<String, double> sumByStatus = {};
      for (var record in records) {
        final status = record['earningStatus'] as String? ?? 'Unknown';
        final fee = (record['platformFee'] ?? 0).toDouble();
        sumByStatus[status] = (sumByStatus[status] ?? 0) + fee;
      }
      return sumByStatus;
    }

    List<Map<String, dynamic>> processRevenueOverTime(List<Map<String, dynamic>> records) {
      final Map<String, double> revenueByDate = {};
      for (var record in records) {
        if (record['earningStatus'] == 'Completed') {
          final timestamp = record['completedAt'] as Timestamp? ?? record['paymentAt'] as Timestamp;
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
              .toIso8601String()
              .substring(0, 10);
          final fee = (record['platformFee'] ?? 0).toDouble();
          revenueByDate[date] = (revenueByDate[date] ?? 0) + fee;
        }
      }
      final sortedDates = revenueByDate.keys.toList()..sort();
      return sortedDates.map((date) => {'date': date, 'revenue': revenueByDate[date]!}).toList();
    }

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalProviders': providersSnapshot.docs.length,
      'totalServices': servicesSnapshot.docs.length,
      'totalPendingServices': pendingServicesSnapshot.docs.length,
      'totalBookings': bookingsSnapshot.docs.length,
      'completedBookings': bookingsSnapshot.docs.where((doc) => doc['status'] == 'Completed').length,
      'totalRevenue': allEarningsRecords.fold(0.0, (sum, record) => sum + (record['platformFee'] ?? 0).toDouble()),
      'totalCategories': categoriesSnapshot.docs.length,
      'userGrowth': processGrowthData(usersSnapshot.docs, 'createdAt'),
      'providerGrowth': processGrowthData(providersSnapshot.docs, 'createdAt'),
      'servicesByCategory': processCategoryData(servicesSnapshot.docs, 'category'),
      'pendingServicesByCategory': processCategoryData(pendingServicesSnapshot.docs, 'category'),
      'topServices': processTopServices(bookingsSnapshot.docs, servicesSnapshot.docs),
      'bookingStatuses': processBookingStatuses(bookingsSnapshot.docs),
      'earningsStatus': processEarningsStatus(allEarningsRecords),
      'revenueOverTime': processRevenueOverTime(allEarningsRecords),
    };
  }

  void navigateOrShowMessage(BuildContext context, String title, Widget Function() screenBuilder) {
    final allowedItems = [
      'Users',
      'Providers',
      'Services',
      'Bookings',
      'Revenue',
      'Manage Categories',
    ];
    if (allowedItems.contains(title)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screenBuilder()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have permission to access $title.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Softer background
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.', style: TextStyle(fontSize: 16)));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dashboard Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                // Stat Cards
                _buildStatCards(data, context),
                const SizedBox(height: 30),
                // Charts
                _buildScrollableChartSection("User Growth", _buildUserGrowthChart(data['userGrowth'])),
                _buildScrollableChartSection("Provider Growth", _buildProviderGrowthChart(data['providerGrowth'])),
                _buildChartSection("Services by Category", _buildServicesByCategoryChart(data['servicesByCategory'])),
                _buildChartSection("Pending Services by Category", _buildPendingServicesByCategoryChart(data['pendingServicesByCategory'])),
                _buildScrollableChartSection("Top Services by Bookings", _buildTopServicesChart(data['topServices'])),
                _buildChartSection("Booking Statuses", _buildBookingStatusesChart(data['bookingStatuses'])),
                _buildChartSection("Earnings Status", _buildEarningsStatusChart(data['earningsStatus'])),
                _buildScrollableChartSection("Revenue Over Time", _buildRevenueOverTimeChart(data['revenueOverTime'])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> data, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Users", "${data['totalUsers']}", Icons.group, chartColors[1], context, () => navigateOrShowMessage(context, "Users", () => UsersScreen()))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Providers", "${data['totalProviders']}", Icons.work, chartColors[0], context, () => navigateOrShowMessage(context, "Providers", () => ProvidersScreen()))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Services", "${data['totalServices']}", Icons.build, chartColors[5], context, () => navigateOrShowMessage(context, "Services", () => ServicesScreen()))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Pending", "${data['totalPendingServices']}", Icons.hourglass_empty, chartColors[4], context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PendingServicesScreen())))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Bookings", "${data['totalBookings']}", Icons.event, chartColors[2], context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Completed", "${data['completedBookings']}", Icons.check_circle, chartColors[3], context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Revenue", "\$${data['totalRevenue'].toStringAsFixed(2)}", Icons.attach_money, chartColors[6], context, () => navigateOrShowMessage(context, "Revenue", () => PaymentsScreen()))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Categories", "${data['totalCategories']}", Icons.category, chartColors[7], context, () => navigateOrShowMessage(context, "Manage Categories", () => ManageCategoriesScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 600, child: chart),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
          ),
          child: chart,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildUserGrowthChart(List<Map<String, dynamic>> userGrowth) {
    if (userGrowth.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: userGrowth.map((point) => FlSpot(DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(), point['count'].toDouble())).toList(),
            isCurved: true,
            color: chartColors[1],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: chartColors[1].withOpacity(0.1)),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _dateTitles)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _numberTitles)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: userGrowth.isNotEmpty ? userGrowth.last['count'] / 5 : 1),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildProviderGrowthChart(List<Map<String, dynamic>> providerGrowth) {
    if (providerGrowth.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: providerGrowth.map((point) => FlSpot(DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(), point['count'].toDouble())).toList(),
            isCurved: true,
            color: chartColors[0],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: chartColors[0].withOpacity(0.1)),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _dateTitles)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _numberTitles)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: providerGrowth.isNotEmpty ? providerGrowth.last['count'] / 5 : 1),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildServicesByCategoryChart(Map<String, int> servicesByCategory) {
    if (servicesByCategory.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: servicesByCategory.entries
                  .map((entry) => PieChartSectionData(
                value: entry.value.toDouble(),
                color: chartColors[servicesByCategory.keys.toList().indexOf(entry.key) % chartColors.length],
                radius: 60,
                showTitle: false,
              ))
                  .toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLegend(servicesByCategory.entries.map((e) => {'label': "${e.key} (${e.value})", 'color': chartColors[servicesByCategory.keys.toList().indexOf(e.key) % chartColors.length]}).toList())),
      ],
    );
  }

  Widget _buildPendingServicesByCategoryChart(Map<String, int> pendingServicesByCategory) {
    if (pendingServicesByCategory.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: pendingServicesByCategory.entries
                  .map((entry) => PieChartSectionData(
                value: entry.value.toDouble(),
                color: chartColors[pendingServicesByCategory.keys.toList().indexOf(entry.key) % chartColors.length],
                radius: 60,
                showTitle: false,
              ))
                  .toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLegend(pendingServicesByCategory.entries.map((e) => {'label': "${e.key} (${e.value})", 'color': chartColors[pendingServicesByCategory.keys.toList().indexOf(e.key) % chartColors.length]}).toList())),
      ],
    );
  }

  Widget _buildTopServicesChart(List<Map<String, dynamic>> topServices) {
    if (topServices.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: topServices.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [BarChartRodData(toY: entry.value['bookings'].toDouble(), color: chartColors[2], width: 20)],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => _serviceTitles(value, meta, topServices))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _numberTitles)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBookingStatusesChart(Map<String, int> bookingStatuses) {
    if (bookingStatuses.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: bookingStatuses.entries
                  .map((entry) => PieChartSectionData(
                value: entry.value.toDouble(),
                color: chartColors[bookingStatuses.keys.toList().indexOf(entry.key) % chartColors.length],
                radius: 60,
                showTitle: false,
              ))
                  .toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLegend(bookingStatuses.entries.map((e) => {'label': "${e.key} (${e.value})", 'color': chartColors[bookingStatuses.keys.toList().indexOf(e.key) % chartColors.length]}).toList())),
      ],
    );
  }

  Widget _buildEarningsStatusChart(Map<String, double> earningsStatus) {
    if (earningsStatus.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: earningsStatus.entries
                  .map((entry) => PieChartSectionData(
                value: entry.value,
                color: chartColors[earningsStatus.keys.toList().indexOf(entry.key) % chartColors.length],
                radius: 60,
                showTitle: false,
              ))
                  .toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLegend(earningsStatus.entries.map((e) => {'label': "${e.key} (\$${e.value.toStringAsFixed(2)})", 'color': chartColors[earningsStatus.keys.toList().indexOf(e.key) % chartColors.length]}).toList())),
      ],
    );
  }

  Widget _buildRevenueOverTimeChart(List<Map<String, dynamic>> revenueOverTime) {
    if (revenueOverTime.isEmpty) return const Center(child: Text("No data available", style: TextStyle(fontSize: 16)));
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: revenueOverTime.map((point) => FlSpot(DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(), point['revenue'])).toList(),
            isCurved: true,
            color: chartColors[6],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: chartColors[6].withOpacity(0.1)),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _dateTitles)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: _numberTitles)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: revenueOverTime.isNotEmpty ? revenueOverTime.map((e) => e['revenue']).reduce((a, b) => a > b ? a : b) / 5 : 1),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> items) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: item['color'], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(item['label'], style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _dateTitles(double value, TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text("${date.month}/${date.day}", style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
    );
  }

  Widget _numberTitles(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
    );
  }

  Widget _serviceTitles(double value, TitleMeta meta, List<Map<String, dynamic>> topServices) {
    final index = value.toInt();
    if (index >= 0 && index < topServices.length) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(topServices[index]['name'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
      );
    }
    return const Text('');
  }

  Widget _buildShimmerEffect() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 16), Expanded(child: _buildShimmerCard())]),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 16), Expanded(child: _buildShimmerCard())]),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 16), Expanded(child: _buildShimmerCard())]),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 16), Expanded(child: _buildShimmerCard())]),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    );
  }
}