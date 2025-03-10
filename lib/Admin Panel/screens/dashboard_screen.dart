import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pie_chart/pie_chart.dart' as PieChartLib;
import 'package:fl_chart/fl_chart.dart' as FlChartLib;
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/payments_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/users_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/services_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/manage_categories.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // Custom color palette inspired by EarningsPage
  static const Color primaryColor = Color(0xFF060644);
  static const Color secondaryColor = Colors.white;
  static const Color accentColor = Color(0xFF4355B9);
  static const List<Color> chartColors = [
    Color(0xFF060644), // Primary color
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF0097A7), // Teal
    Color(0xFFC2185B), // Pink
    Color(0xFF455A64), // Blue Grey
    Color(0xFF5D4037), // Brown
    Color(0xFF00796B), // Dark Teal
    Color(0xFF3949AB), // Indigo
    Color(0xFF6D4C41), // Dark Brown
  ];

  Future<Map<String, dynamic>> fetchDashboardData() async {
    // Fetch collections
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final providersSnapshot = await FirebaseFirestore.instance.collection('providers').get();
    final servicesSnapshot = await FirebaseFirestore.instance.collection('services').get();
    final pendingServicesSnapshot = await FirebaseFirestore.instance.collection('pending_services').get();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();

    // Fetch earnings data
    final earningsSnapshot = await FirebaseFirestore.instance.collection('earnings').get();

    // Calculate total platform fee (revenue) from all providers' records
    double totalRevenue = 0.0;
    for (var providerDoc in earningsSnapshot.docs) {
      final recordsSnapshot = await providerDoc.reference.collection('records').get();
      for (var recordDoc in recordsSnapshot.docs) {
        final recordData = recordDoc.data();
        final platformFee = (recordData['platformFee'] ?? 0).toDouble();
        totalRevenue += platformFee;
      }
    }

    // Process all earnings records for analysis
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
      return sortedServices.take(8).map((entry) => {
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
      'totalRevenue': totalRevenue,
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  _buildStatCards(data, context),
                  const SizedBox(height: 24),
                  _buildChartSection("User Growth", _buildUserGrowthChart(data['userGrowth'])),
                  _buildChartSection("Provider Growth", _buildProviderGrowthChart(data['providerGrowth'])),
                  _buildChartSection("Services by Category", _buildServicesByCategoryChart(data['servicesByCategory'])),
                  _buildChartSection("Pending Services by Category", _buildPendingServicesByCategoryChart(data['pendingServicesByCategory'])),
                  _buildChartSection("Top Services by Bookings", _buildTopServicesChart(data['topServices'])),
                  _buildChartSection("Booking Statuses", _buildBookingStatusesChart(data['bookingStatuses'])),
                  _buildChartSection("Earnings Status", _buildEarningsStatusChart(data['earningsStatus'])),
                  _buildChartSection("Revenue Over Time", _buildRevenueOverTimeChart(data['revenueOverTime'])),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> data, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard("Users", "${data['totalUsers']}", Icons.group, chartColors[1], context, () => navigateOrShowMessage(context, "Users", () => UsersScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard("Providers", "${data['totalProviders']}", Icons.work, chartColors[2], context, () => navigateOrShowMessage(context, "Providers", () => ProvidersScreen()))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard("Services", "${data['totalServices']}", Icons.build, chartColors[5], context, () => navigateOrShowMessage(context, "Services", () => ServicesScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard("Pending", "${data['totalPendingServices']}", Icons.hourglass_empty, chartColors[3], context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PendingServicesScreen())))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard("Bookings", "${data['totalBookings']}", Icons.event, chartColors[0], context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard("Completed", "${data['completedBookings']}", Icons.check_circle, chartColors[6], context, () => navigateOrShowMessage(context, "Bookings", () => BookingsScreen()))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard("Revenue", "\$${data['totalRevenue'].toStringAsFixed(2)}", Icons.attach_money, chartColors[4], context, () => navigateOrShowMessage(context, "Revenue", () => PaymentsScreen()))),
            const SizedBox(width: 10),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 300,
            child: chart,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserGrowthChart(List<Map<String, dynamic>> userGrowth) {
    if (userGrowth.isEmpty) {
      return _buildEmptyChart();
    }

    final maxCount = userGrowth.isNotEmpty
        ? userGrowth.map((e) => e['count'] as num).reduce((a, b) => a > b ? a : b).toDouble()
        : 10;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width - 64,
            userGrowth.length * 30.0),
        child: FlChartLib.LineChart(
          FlChartLib.LineChartData(
            lineBarsData: [
              FlChartLib.LineChartBarData(
                spots: userGrowth
                    .map((point) => FlChartLib.FlSpot(
                  DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(),
                  point['count'].toDouble(),
                ))
                    .toList(),
                isCurved: true,
                color: chartColors[1],
                dotData: FlChartLib.FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlChartLib.FlDotCirclePainter(
                    radius: 4,
                    color: chartColors[1],
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: FlChartLib.BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      chartColors[1].withOpacity(0.4),
                      chartColors[1].withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minY: 0,
            maxY: maxCount * 1.2,
            titlesData: FlChartLib.FlTitlesData(
              bottomTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _dateTitles,
                  interval: 86400000 * 5,
                ),
              ),
              leftTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: maxCount / 5,
                ),
              ),
              topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
            ),
            gridData: FlChartLib.FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxCount / 5,
              verticalInterval: 86400000 * 5,
              getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlChartLib.FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            lineTouchData: FlChartLib.LineTouchData(
              touchTooltipData: FlChartLib.LineTouchTooltipData(
                //tooltipBgColor: Colors.white.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                    return FlChartLib.LineTooltipItem(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n',
                      const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'Users: ${touchedSpot.y.toInt()}',
                          style: TextStyle(color: chartColors[1], fontWeight: FontWeight.normal),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              touchSpotThreshold: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderGrowthChart(List<Map<String, dynamic>> providerGrowth) {
    if (providerGrowth.isEmpty) {
      return _buildEmptyChart();
    }

    final maxCount = providerGrowth.isNotEmpty
        ? providerGrowth.map((e) => e['count'] as num).reduce((a, b) => a > b ? a : b).toDouble()
        : 10;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width - 64,
            providerGrowth.length * 30.0),
        child: FlChartLib.LineChart(
          FlChartLib.LineChartData(
            lineBarsData: [
              FlChartLib.LineChartBarData(
                spots: providerGrowth
                    .map((point) => FlChartLib.FlSpot(
                  DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(),
                  point['count'].toDouble(),
                ))
                    .toList(),
                isCurved: true,
                color: chartColors[2],
                dotData: FlChartLib.FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlChartLib.FlDotCirclePainter(
                    radius: 4,
                    color: chartColors[2],
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: FlChartLib.BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      chartColors[2].withOpacity(0.4),
                      chartColors[2].withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minY: 0,
            maxY: maxCount * 1.2,
            titlesData: FlChartLib.FlTitlesData(
              bottomTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _dateTitles,
                  interval: 86400000 * 5,
                ),
              ),
              leftTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: maxCount / 5,
                ),
              ),
              topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
            ),
            gridData: FlChartLib.FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxCount / 5,
              verticalInterval: 86400000 * 5,
              getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlChartLib.FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            lineTouchData: FlChartLib.LineTouchData(
              touchTooltipData: FlChartLib.LineTouchTooltipData(
                //tooltipBgColor: Colors.white.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                    return FlChartLib.LineTooltipItem(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n',
                      const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'Providers: ${touchedSpot.y.toInt()}',
                          style: TextStyle(color: chartColors[2], fontWeight: FontWeight.normal),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              touchSpotThreshold: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesByCategoryChart(Map<String, int> servicesByCategory) {
    if (servicesByCategory.isEmpty) {
      return _buildEmptyChart();
    }

    final total = servicesByCategory.values.fold(0, (sum, value) => sum + value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChartLib.PieChart(
            dataMap: servicesByCategory.map((key, value) => MapEntry(key, value.toDouble())),
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            colorList: servicesByCategory.keys.map((key) {
              final index = servicesByCategory.keys.toList().indexOf(key);
              return chartColors[index % chartColors.length];
            }).toList(),
            chartType: PieChartLib.ChartType.ring,
            centerText: "Services",
            legendOptions: const PieChartLib.LegendOptions(showLegends: false),
            chartValuesOptions: const PieChartLib.ChartValuesOptions(
              showChartValuesInPercentage: false,
              showChartValues: false,
            ),
            ringStrokeWidth: 30,
            chartRadius: 150,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: servicesByCategory.entries.map((entry) {
            final index = servicesByCategory.keys.toList().indexOf(entry.key);
            final color = chartColors[index % chartColors.length];
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: $percentage% (${entry.value})',
                    style: const TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPendingServicesByCategoryChart(Map<String, int> pendingServicesByCategory) {
    if (pendingServicesByCategory.isEmpty) {
      return _buildEmptyChart();
    }

    final total = pendingServicesByCategory.values.fold(0, (sum, value) => sum + value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChartLib.PieChart(
            dataMap: pendingServicesByCategory.map((key, value) => MapEntry(key, value.toDouble())),
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            colorList: pendingServicesByCategory.keys.map((key) {
              final index = pendingServicesByCategory.keys.toList().indexOf(key);
              return chartColors[index % chartColors.length];
            }).toList(),
            chartType: PieChartLib.ChartType.ring,
            centerText: "Pending",
            legendOptions: const PieChartLib.LegendOptions(showLegends: false),
            chartValuesOptions: const PieChartLib.ChartValuesOptions(
              showChartValuesInPercentage: false,
              showChartValues: false,
            ),
            ringStrokeWidth: 30,
            chartRadius: 150,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: pendingServicesByCategory.entries.map((entry) {
            final index = pendingServicesByCategory.keys.toList().indexOf(entry.key);
            final color = chartColors[index % chartColors.length];
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: $percentage% (${entry.value})',
                    style: const TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopServicesChart(List<Map<String, dynamic>> topServices) {
    if (topServices.isEmpty) {
      return _buildEmptyChart();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width - 64,
            topServices.length * 60.0),
        child: FlChartLib.BarChart(
          FlChartLib.BarChartData(
            alignment: FlChartLib.BarChartAlignment.spaceAround,
            barGroups: topServices.asMap().entries.map((entry) {
              return FlChartLib.BarChartGroupData(
                x: entry.key,
                barRods: [
                  FlChartLib.BarChartRodData(
                    toY: entry.value['bookings'].toDouble(),
                    color: chartColors[entry.key % chartColors.length],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlChartLib.FlTitlesData(
              bottomTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => _serviceTitles(value, meta, topServices),
                ),
              ),
              leftTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: topServices.map((e) => e['bookings'] as num).reduce((a, b) => a > b ? a : b).toDouble() / 5,
                ),
              ),
              topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
            ),
            gridData: FlChartLib.FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: topServices.map((e) => e['bookings'] as num).reduce((a, b) => a > b ? a : b).toDouble() / 5,
              getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlChartLib.FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            barTouchData: FlChartLib.BarTouchData(
              touchTooltipData: FlChartLib.BarTouchTooltipData(
                //tooltipBgColor: Colors.white.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final service = topServices[group.x.toInt()];
                  return FlChartLib.BarTooltipItem(
                    '${service['name']}\n',
                    const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: 'Bookings: ${rod.toY.toInt()}',
                        style: TextStyle(color: chartColors[groupIndex % chartColors.length]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingStatusesChart(Map<String, int> bookingStatuses) {
    if (bookingStatuses.isEmpty) {
      return _buildEmptyChart();
    }

    final total = bookingStatuses.values.fold(0, (sum, value) => sum + value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChartLib.PieChart(
            dataMap: bookingStatuses.map((key, value) => MapEntry(key, value.toDouble())),
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            colorList: bookingStatuses.keys.map((key) {
              final index = bookingStatuses.keys.toList().indexOf(key);
              return chartColors[index % chartColors.length];
            }).toList(),
            chartType: PieChartLib.ChartType.ring,
            centerText: "Bookings",
            legendOptions: const PieChartLib.LegendOptions(showLegends: false),
            chartValuesOptions: const PieChartLib.ChartValuesOptions(
              showChartValuesInPercentage: false,
              showChartValues: false,
            ),
            ringStrokeWidth: 30,
            chartRadius: 150,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: bookingStatuses.entries.map((entry) {
            final index = bookingStatuses.keys.toList().indexOf(entry.key);
            final color = chartColors[index % chartColors.length];
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: $percentage% (${entry.value})',
                    style: const TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEarningsStatusChart(Map<String, double> earningsStatus) {
    if (earningsStatus.isEmpty) {
      return _buildEmptyChart();
    }

    final total = earningsStatus.values.fold(0.0, (sum, value) => sum + value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChartLib.PieChart(
            dataMap: earningsStatus,
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            colorList: earningsStatus.keys.map((key) {
              final index = earningsStatus.keys.toList().indexOf(key);
              return chartColors[index % chartColors.length];
            }).toList(),
            chartType: PieChartLib.ChartType.ring,
            centerText: "Earnings",
            legendOptions: const PieChartLib.LegendOptions(showLegends: false),
            chartValuesOptions: const PieChartLib.ChartValuesOptions(
              showChartValuesInPercentage: false,
              showChartValues: false,
            ),
            ringStrokeWidth: 30,
            chartRadius: 150,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: earningsStatus.entries.map((entry) {
            final index = earningsStatus.keys.toList().indexOf(entry.key);
            final color = chartColors[index % chartColors.length];
            final percentage = ((entry.value / total) * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: $percentage% (\$${entry.value.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRevenueOverTimeChart(List<Map<String, dynamic>> revenueOverTime) {
    if (revenueOverTime.isEmpty) {
      return _buildEmptyChart();
    }

    final maxRevenue = revenueOverTime.isNotEmpty
        ? revenueOverTime.map((e) => e['revenue'] as num).reduce((a, b) => a > b ? a : b).toDouble()
        : 10.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width - 64,
            revenueOverTime.length * 30.0),
        child: FlChartLib.LineChart(
          FlChartLib.LineChartData(
            lineBarsData: [
              FlChartLib.LineChartBarData(
                spots: revenueOverTime
                    .map((point) => FlChartLib.FlSpot(
                  DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(),
                  point['revenue'].toDouble(),
                ))
                    .toList(),
                isCurved: true,
                color: chartColors[4],
                dotData: FlChartLib.FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlChartLib.FlDotCirclePainter(
                    radius: 4,
                    color: chartColors[4],
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: FlChartLib.BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      chartColors[4].withOpacity(0.4),
                      chartColors[4].withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minY: 0,
            maxY: maxRevenue * 1.2,
            titlesData: FlChartLib.FlTitlesData(
              bottomTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _dateTitles,
                  interval: 86400000 * 5,
                ),
              ),
              leftTitles: FlChartLib.AxisTitles(
                sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: maxRevenue / 5,
                ),
              ),
              topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
            ),
            gridData: FlChartLib.FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxRevenue / 5,
              verticalInterval: 86400000 * 5,
              getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlChartLib.FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlChartLib.FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            lineTouchData: FlChartLib.LineTouchData(
              touchTooltipData: FlChartLib.LineTouchTooltipData(
                //tooltipBgColor: Colors.white.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                    return FlChartLib.LineTooltipItem(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n',
                      const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'Revenue: \$${touchedSpot.y.toStringAsFixed(2)}',
                          style: TextStyle(color: chartColors[4], fontWeight: FontWeight.normal),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              touchSpotThreshold: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _dateTitles(double value, FlChartLib.TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${date.month}/${date.day}',
        style: const TextStyle(fontSize: 12, color: primaryColor),
      ),
    );
  }

  Widget _numberTitles(double value, FlChartLib.TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 12, color: primaryColor),
      ),
    );
  }

  Widget _serviceTitles(double value, FlChartLib.TitleMeta meta, List<Map<String, dynamic>> topServices) {
    final index = value.toInt();
    if (index >= 0 && index < topServices.length) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          topServices[index]['name'],
          style: const TextStyle(fontSize: 12, color: primaryColor),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const Text('');
  }

  Widget _buildShimmerEffect() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerCard()),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerCard()),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerCard()),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _buildShimmerCard()),
            ]),
            const SizedBox(height: 24),
            Container(height: 300, color: Colors.white),
            const SizedBox(height: 24),
            Container(height: 300, color: Colors.white),
            const SizedBox(height: 24),
            Container(height: 300, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

double max(double a, double b) => a > b ? a : b;