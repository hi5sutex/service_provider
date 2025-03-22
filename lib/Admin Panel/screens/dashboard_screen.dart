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
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryColor = Color(0xFF060644);
  static const Color secondaryColor = Colors.white;
  static const Color accentColor = Color(0xFF4355B9);
  static const List<Color> chartColors = [
    Color(0xFF060644),
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF0097A7),
    Color(0xFFC2185B),
    Color(0xFF455A64),
    Color(0xFF5D4037),
    Color(0xFF00796B),
    Color(0xFF3949AB),
    Color(0xFF6D4C41),
  ];
  static final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  static final monthFormat = DateFormat('MMM'); // For formatting month names (e.g., Apr)

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final providersSnapshot = await FirebaseFirestore.instance.collection('providers').get();
    final servicesSnapshot = await FirebaseFirestore.instance.collection('services').get();
    final pendingServicesSnapshot = await FirebaseFirestore.instance.collection('pending_services').get();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
    final earningsSnapshot = await FirebaseFirestore.instance.collection('earnings').get();

    double totalRevenue = 0.0;
    List<Map<String, dynamic>> allEarningsRecords = [];
    for (var providerDoc in earningsSnapshot.docs) {
      final recordsSnapshot = await providerDoc.reference.collection('records').get();
      for (var recordDoc in recordsSnapshot.docs) {
        final recordData = recordDoc.data();
        final platformFee = (recordData['platformFee'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += platformFee;
        allEarningsRecords.add(recordData);
      }
    }

    Map<String, dynamic> processGrowthData(List<QueryDocumentSnapshot> docs, String dateField) {
      final Map<String, int> countByMonthYear = {};
      String? firstYear;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey(dateField)) {
          final timestamp = data[dateField] as Timestamp?;
          if (timestamp != null) {
            try {
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
              final monthYear = "${date.year}-${date.month.toString().padLeft(2, '0')}"; // e.g., 2023-04
              countByMonthYear[monthYear] = (countByMonthYear[monthYear] ?? 0) + 1;
              firstYear ??= date.year.toString();
            } catch (e) {
              print("Error parsing timestamp for doc ${doc.id}: $e");
              continue;
            }
          }
        }
      }

      final sortedKeys = countByMonthYear.keys.toList()..sort();
      return {
        'data': sortedKeys.map((key) {
          final parts = key.split('-');
          return {
            'year': int.parse(parts[0]),
            'month': int.parse(parts[1]),
            'count': countByMonthYear[key]!,
          };
        }).toList(),
        'year': firstYear ?? DateTime.now().year.toString(),
      };
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
        final serviceId = doc['serviceId'] as String?;
        if (serviceId != null) {
          bookingsByService[serviceId] = (bookingsByService[serviceId] ?? 0) + 1;
        }
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
        final fee = (record['platformFee'] as num?)?.toDouble() ?? 0.0;
        sumByStatus[status] = (sumByStatus[status] ?? 0) + fee;
      }
      return sumByStatus;
    }

    List<Map<String, dynamic>> processRevenueOverTime(List<Map<String, dynamic>> records) {
      final Map<String, double> revenueByDate = {};
      for (var record in records) {
        if (record['earningStatus'] == 'Completed') {
          final timestamp = record['completedAt'] as Timestamp? ?? record['paymentAt'] as Timestamp?;
          if (timestamp != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
                .toIso8601String()
                .substring(0, 10);
            final fee = (record['platformFee'] as num?)?.toDouble() ?? 0.0;
            revenueByDate[date] = (revenueByDate[date] ?? 0) + fee;
          }
        }
      }
      final sortedDates = revenueByDate.keys.toList()..sort();
      return sortedDates.map((date) => {'date': date, 'revenue': revenueByDate[date]!}).toList();
    }

    final userGrowthData = processGrowthData(usersSnapshot.docs, 'createdAt');
    final providerGrowthData = processGrowthData(providersSnapshot.docs, 'createdAt');

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalProviders': providersSnapshot.docs.length,
      'totalServices': servicesSnapshot.docs.length,
      'totalPendingServices': pendingServicesSnapshot.docs.length,
      'totalBookings': bookingsSnapshot.docs.length,
      'completedBookings': bookingsSnapshot.docs.where((doc) => doc['status'] == 'Completed').length,
      'totalRevenue': totalRevenue,
      'totalCategories': categoriesSnapshot.docs.length,
      'userGrowth': userGrowthData['data'],
      'userGrowthYear': userGrowthData['year'],
      'providerGrowth': providerGrowthData['data'],
      'providerGrowthYear': providerGrowthData['year'],
      'servicesByCategory': processCategoryData(servicesSnapshot.docs, 'category'),
      'pendingServicesByCategory': processCategoryData(pendingServicesSnapshot.docs, 'category'),
      'topServices': processTopServices(bookingsSnapshot.docs, servicesSnapshot.docs),
      'bookingStatuses': processBookingStatuses(bookingsSnapshot.docs),
      'earningsStatus': processEarningsStatus(allEarningsRecords),
      'revenueOverTime': processRevenueOverTime(allEarningsRecords),
    };
  }

  void navigateOrShowMessage(BuildContext context, String title, Widget Function() screenBuilder) {
    final allowedItems = ['Users', 'Providers', 'Services', 'Bookings', 'Revenue', 'Manage Categories'];
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
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: secondaryColor),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
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
                  _buildStatCards(data, context),
                  const SizedBox(height: 24),
                  _buildChartSection("User Growth", _buildUserGrowthChart(data['userGrowth'], data['userGrowthYear'])),
                  _buildChartSection("Provider Growth", _buildProviderGrowthChart(data['providerGrowth'], data['providerGrowthYear'])),
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
            Expanded(child: _buildStatCard("Revenue", currencyFormat.format(data['totalRevenue']), Icons.attach_money, chartColors[4], context, () => navigateOrShowMessage(context, "Revenue", () => PaymentsScreen()))),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                  style: TextStyle(fontSize: 14, color: primaryColor.withOpacity(0.7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              Icon(Icons.bubble_chart, color: primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: SizedBox(height: 300, child: chart),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(List<Map<String, dynamic>> userGrowth, String year) {
    if (userGrowth.isEmpty) return _buildEmptyChart();
    final maxCount = userGrowth.map((e) => e['count'] as num).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: [
        Text(
          year,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FlChartLib.BarChart(
            FlChartLib.BarChartData(
              alignment: FlChartLib.BarChartAlignment.spaceAround,
              barGroups: userGrowth.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return FlChartLib.BarChartGroupData(
                  x: index,
                  barRods: [
                    FlChartLib.BarChartRodData(
                      toY: data['count'].toDouble(),
                      color: chartColors[1],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlChartLib.FlTitlesData(
                bottomTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => _monthTitles(value, meta, userGrowth),
                )),
                leftTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: maxCount / 5,
                )),
                topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
                rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              ),
              gridData: FlChartLib.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCount / 5,
                getDrawingHorizontalLine: (value) => FlChartLib.FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),
              borderData: FlChartLib.FlBorderData(show: false),
              barTouchData: FlChartLib.BarTouchData(
                touchTooltipData: FlChartLib.BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthData = userGrowth[group.x.toInt()];
                    final monthName = monthFormat.format(DateTime(monthData['year'], monthData['month']));
                    return FlChartLib.BarTooltipItem(
                      '$monthName ${monthData['year']}\nUsers: ${rod.toY.toInt()}',
                      const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderGrowthChart(List<Map<String, dynamic>> providerGrowth, String year) {
    if (providerGrowth.isEmpty) return _buildEmptyChart();
    final maxCount = providerGrowth.map((e) => e['count'] as num).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: [
        Text(
          year,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FlChartLib.BarChart(
            FlChartLib.BarChartData(
              alignment: FlChartLib.BarChartAlignment.spaceAround,
              barGroups: providerGrowth.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return FlChartLib.BarChartGroupData(
                  x: index,
                  barRods: [
                    FlChartLib.BarChartRodData(
                      toY: data['count'].toDouble(),
                      color: chartColors[2],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlChartLib.FlTitlesData(
                bottomTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => _monthTitles(value, meta, providerGrowth),
                )),
                leftTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: _numberTitles,
                  interval: maxCount / 5,
                )),
                topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
                rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              ),
              gridData: FlChartLib.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCount / 5,
                getDrawingHorizontalLine: (value) => FlChartLib.FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),
              borderData: FlChartLib.FlBorderData(show: false),
              barTouchData: FlChartLib.BarTouchData(
                touchTooltipData: FlChartLib.BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthData = providerGrowth[group.x.toInt()];
                    final monthName = monthFormat.format(DateTime(monthData['year'], monthData['month']));
                    return FlChartLib.BarTooltipItem(
                      '$monthName ${monthData['year']}\nProviders: ${rod.toY.toInt()}',
                      const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesByCategoryChart(Map<String, int> servicesByCategory) {
    if (servicesByCategory.isEmpty) return _buildEmptyChart();

    // Calculate total services to compute percentages
    final totalServices = servicesByCategory.values.reduce((a, b) => a + b);
    final sortedCategories = servicesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by value (descending)

    // Convert to a list of maps with percentage and color
    final List<Map<String, dynamic>> categoryData = sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category.value / totalServices * 100).toInt();
      return {
        'name': category.key,
        'count': category.value,
        'percentage': percentage,
        'color': chartColors[index % chartColors.length].withOpacity(0.2), // Lighter opacity for circles
      };
    }).toList();

    // Calculate circle sizes based on percentages
    const double maxRadius = 60.0; // Reduced max radius for better fit
    const double minRadius = 30.0; // Minimum radius for the smallest circle
    final maxPercentage = categoryData.map((e) => e['percentage'] as int).reduce(math.max);
    final minPercentage = categoryData.map((e) => e['percentage'] as int).reduce(math.min);

    // Map percentages to radius sizes
    for (var data in categoryData) {
      final percentage = data['percentage'] as int;
      if (maxPercentage == minPercentage) {
        data['radius'] = (maxRadius + minRadius) / 2;
      } else {
        final normalized = (percentage - minPercentage) / (maxPercentage - minPercentage);
        data['radius'] = minRadius + (maxRadius - minRadius) * normalized;
      }
    }

    // Calculate total width needed for all circles
    const double spacing = 20.0; // Space between circles
    double totalWidth = 0.0;
    for (var data in categoryData) {
      final radius = data['radius'] as double;
      totalWidth += (radius * 2) + spacing; // Diameter + spacing
    }
    totalWidth -= spacing; // Remove the last spacing

    // Ensure the total width is at least the screen width for small datasets
    totalWidth = math.max(totalWidth, MediaQuery.of(context).size.width - 64);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: totalWidth,
            height: 200, // Adjusted height to fit circles and leave space for legend
            child: Stack(
              children: () {
                double currentX = 0.0;
                return categoryData.asMap().entries.map((entry) {
                  final data = entry.value;
                  final radius = data['radius'] as double;
                  final circleWidget = Positioned(
                    left: currentX,
                    top: 100 - radius, // Center vertically within the 200px height
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${data['name']}: ${data['count']} services (${data['percentage']}%)')),
                        );
                      },
                      child: Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data['color'],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${data['percentage']}%',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: radius < 40 ? 12 : 16, // Adjust font size based on circle size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  currentX += (radius * 2) + spacing; // Move to the next position
                  return circleWidget;
                }).toList();
              }(),
            ),
          ),
          const SizedBox(height: 16),
          // Legend (also scrollable if needed)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: totalWidth,
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: categoryData.map((data) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data['color'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['name'],
                        style: const TextStyle(fontSize: 12, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data['count']}',
                        style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingServicesByCategoryChart(Map<String, int> pendingServicesByCategory) {
    if (pendingServicesByCategory.isEmpty) return _buildEmptyChart();

    // Calculate total pending services to compute percentages
    final totalPendingServices = pendingServicesByCategory.values.reduce((a, b) => a + b);
    final sortedCategories = pendingServicesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by value (descending)

    // Convert to a list of maps with percentage and color
    final List<Map<String, dynamic>> categoryData = sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category.value / totalPendingServices * 100).toInt();
      return {
        'name': category.key,
        'count': category.value,
        'percentage': percentage,
        'color': chartColors[index % chartColors.length].withOpacity(0.2), // Lighter opacity for circles
      };
    }).toList();

    // Calculate circle sizes based on percentages
    const double maxRadius = 60.0; // Reduced max radius for better fit
    const double minRadius = 30.0; // Minimum radius for the smallest circle
    final maxPercentage = categoryData.map((e) => e['percentage'] as int).reduce(math.max);
    final minPercentage = categoryData.map((e) => e['percentage'] as int).reduce(math.min);

    // Map percentages to radius sizes
    for (var data in categoryData) {
      final percentage = data['percentage'] as int;
      if (maxPercentage == minPercentage) {
        data['radius'] = (maxRadius + minRadius) / 2;
      } else {
        final normalized = (percentage - minPercentage) / (maxPercentage - minPercentage);
        data['radius'] = minRadius + (maxRadius - minRadius) * normalized;
      }
    }

    // Calculate total width needed for all circles
    const double spacing = 20.0; // Space between circles
    double totalWidth = 0.0;
    for (var data in categoryData) {
      final radius = data['radius'] as double;
      totalWidth += (radius * 2) + spacing; // Diameter + spacing
    }
    totalWidth -= spacing; // Remove the last spacing

    // Ensure the total width is at least the screen width for small datasets
    totalWidth = math.max(totalWidth, MediaQuery.of(context).size.width - 64);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: totalWidth,
            height: 200, // Adjusted height to fit circles and leave space for legend
            child: Stack(
              children: () {
                double currentX = 0.0;
                return categoryData.asMap().entries.map((entry) {
                  final data = entry.value;
                  final radius = data['radius'] as double;
                  final circleWidget = Positioned(
                    left: currentX,
                    top: 100 - radius, // Center vertically within the 200px height
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${data['name']}: ${data['count']} pending services (${data['percentage']}%)')),
                        );
                      },
                      child: Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data['color'],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${data['percentage']}%',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: radius < 40 ? 12 : 16, // Adjust font size based on circle size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  currentX += (radius * 2) + spacing; // Move to the next position
                  return circleWidget;
                }).toList();
              }(),
            ),
          ),
          const SizedBox(height: 16),
          // Legend (also scrollable if needed)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: totalWidth,
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: categoryData.map((data) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data['color'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['name'],
                        style: const TextStyle(fontSize: 12, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data['count']}',
                        style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServicesChart(List<Map<String, dynamic>> topServices) {
    if (topServices.isEmpty) return _buildEmptyChart();

    final maxBookings = topServices.map((e) => e['bookings'] as num).reduce((a, b) => a > b ? a : b).toDouble();

    // Calculate total width needed for all bars
    const double barWidth = 20.0;
    const double spacing = 40.0; // Space between bars
    double totalWidth = topServices.length * (barWidth + spacing) - spacing; // Remove the last spacing
    totalWidth = math.max(totalWidth, MediaQuery.of(context).size.width - 64);

    // Prepare data for the legend
    final List<Map<String, dynamic>> serviceData = topServices.asMap().entries.map((entry) {
      final index = entry.key;
      final service = entry.value;
      return {
        'name': service['name'],
        'bookings': service['bookings'],
        'color': chartColors[index % chartColors.length], // Use the same color as the bar
      };
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: totalWidth,
            height: 200, // Adjusted height to fit the chart and leave space for legend
            child: FlChartLib.BarChart(
              FlChartLib.BarChartData(
                alignment: FlChartLib.BarChartAlignment.spaceAround,
                barGroups: topServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  return FlChartLib.BarChartGroupData(
                    x: index,
                    barRods: [
                      FlChartLib.BarChartRodData(
                        toY: entry.value['bookings'].toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            chartColors[entry.key % chartColors.length],
                            chartColors[entry.key % chartColors.length].withOpacity(0.8),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlChartLib.FlTitlesData(
                  bottomTitles: const FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false), // Hide x-axis titles
                  ),
                  leftTitles: FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: _numberTitles,
                      interval: maxBookings / 5,
                    ),
                  ),
                  topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
                  rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
                ),
                gridData: FlChartLib.FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxBookings / 5,
                  getDrawingHorizontalLine: (value) => FlChartLib.FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                ),
                borderData: FlChartLib.FlBorderData(show: false),
                barTouchData: FlChartLib.BarTouchData(
                  touchTooltipData: FlChartLib.BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final service = topServices[group.x.toInt()];
                      return FlChartLib.BarTooltipItem(
                        '${service['name']}\nBookings: ${rod.toY.toInt()}',
                        const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend (also scrollable if needed)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: totalWidth,
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: serviceData.map((data) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle, // Use a rectangle to match the bar shape
                          color: data['color'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['name'],
                        style: const TextStyle(fontSize: 12, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data['bookings']}',
                        style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusesChart(Map<String, int> bookingStatuses) {
    if (bookingStatuses.isEmpty) return _buildEmptyChart();
    final dataMap = bookingStatuses.map((key, value) => MapEntry(key, value.toDouble()));
    final colorList = bookingStatuses.keys.map((key) => chartColors[bookingStatuses.keys.toList().indexOf(key) % chartColors.length]).toList();
    return PieChartLib.PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      colorList: colorList,
      chartType: PieChartLib.ChartType.ring,
      centerText: "Bookings",
      legendOptions: const PieChartLib.LegendOptions(
        showLegends: true,
        legendPosition: PieChartLib.LegendPosition.bottom,
        showLegendsInRow: false,
        legendTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryColor),
      ),
      chartValuesOptions: const PieChartLib.ChartValuesOptions(
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 1,
        chartValueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      ringStrokeWidth: 25,
      chartRadius: MediaQuery.of(context).size.width / 2.5,
      gradientList: bookingStatuses.keys.map((key) {
        final index = bookingStatuses.keys.toList().indexOf(key);
        final color = chartColors[index % chartColors.length];
        return [color, color.withOpacity(0.8)];
      }).toList(),
    );
  }

  Widget _buildEarningsStatusChart(Map<String, double> earningsStatus) {
    if (earningsStatus.isEmpty) return _buildEmptyChart();
    final dataMap = earningsStatus;
    final colorList = earningsStatus.keys.map((key) => chartColors[earningsStatus.keys.toList().indexOf(key) % chartColors.length]).toList();
    return PieChartLib.PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      colorList: colorList,
      chartType: PieChartLib.ChartType.ring,
      centerText: "Earnings",
      legendOptions: const PieChartLib.LegendOptions(
        showLegends: true,
        legendPosition: PieChartLib.LegendPosition.bottom,
        showLegendsInRow: false,
        legendTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryColor),
      ),
      chartValuesOptions: const PieChartLib.ChartValuesOptions(
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 1,
        chartValueStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      ringStrokeWidth: 25,
      chartRadius: MediaQuery.of(context).size.width / 2.5,
      gradientList: earningsStatus.keys.map((key) {
        final index = earningsStatus.keys.toList().indexOf(key);
        final color = chartColors[index % chartColors.length];
        return [color, color.withOpacity(0.8)];
      }).toList(),
    );
  }

  Widget _buildRevenueOverTimeChart(List<Map<String, dynamic>> revenueOverTime) {
    if (revenueOverTime.isEmpty) return _buildEmptyChart();
    final maxRevenue = revenueOverTime.map((e) => e['revenue'] as num).reduce((a, b) => a > b ? a : b).toDouble();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: max(MediaQuery.of(context).size.width - 64, revenueOverTime.length * 40.0),
        child: FlChartLib.LineChart(
          FlChartLib.LineChartData(
            lineBarsData: [
              FlChartLib.LineChartBarData(
                spots: revenueOverTime.map((point) => FlChartLib.FlSpot(
                  DateTime.parse(point['date']).millisecondsSinceEpoch.toDouble(),
                  point['revenue'].toDouble(),
                )).toList(),
                isCurved: true,
                color: chartColors[4],
                dotData: const FlChartLib.FlDotData(show: false),
                belowBarData: FlChartLib.BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [chartColors[4].withOpacity(0.4), chartColors[4].withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minY: 0,
            maxY: maxRevenue * 1.2,
            titlesData: FlChartLib.FlTitlesData(
              bottomTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: _dateTitles,
                interval: 86400000 * 5,
              )),
              leftTitles: FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: _currencyTitles,
                interval: maxRevenue / 5,
              )),
              topTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
              rightTitles: const FlChartLib.AxisTitles(sideTitles: FlChartLib.SideTitles(showTitles: false)),
            ),
            gridData: FlChartLib.FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxRevenue / 5,
              verticalInterval: 86400000 * 5,
              getDrawingHorizontalLine: (value) => FlChartLib.FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              getDrawingVerticalLine: (value) => FlChartLib.FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1, dashArray: [5, 5]),
            ),
            borderData: FlChartLib.FlBorderData(show: false),
            lineTouchData: FlChartLib.LineTouchData(
              touchTooltipData: FlChartLib.LineTouchTooltipData(
                getTooltipColor: (_) => Colors.white.withOpacity(0.9),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  return FlChartLib.LineTooltipItem(
                    '${date.month}/${date.day}/${date.year}\n${currencyFormat.format(spot.y)}',
                    const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }).toList(),
              ),
              handleBuiltInTouches: true,
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
          Icon(Icons.bubble_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _dateTitles(double value, FlChartLib.TitleMeta meta, [double? customInterval]) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${date.month}/${date.day}',
        style: const TextStyle(fontSize: 12, color: primaryColor),
      ),
    );
  }

  Widget _monthTitles(double value, FlChartLib.TitleMeta meta, List<Map<String, dynamic>> data) {
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      final monthData = data[index];
      final monthName = monthFormat.format(DateTime(monthData['year'], monthData['month']));
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          monthName,
          style: const TextStyle(fontSize: 12, color: primaryColor),
        ),
      );
    }
    return const Text('');
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

  Widget _currencyTitles(double value, FlChartLib.TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        currencyFormat.format(value),
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
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
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
            ...List.generate(8, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
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