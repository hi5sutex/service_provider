import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pie_chart/pie_chart.dart' as PieChartLib;
import 'package:fl_chart/fl_chart.dart' as FlChartLib;
import 'package:service_provider/Admin%20Panel/screens/PendingServicesScreen.dart';
import 'package:service_provider/Admin%20Panel/screens/bookings_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/users_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/providers_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/services_screen.dart';
import 'package:service_provider/Admin%20Panel/screens/manage_categories.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color secondaryColor = Colors.white;
  static const Color accentColor = Color(0xFF3F51B5);
  static const Color backgroundColor = Color(0xFFF5F6FA);

  static const List<Color> chartColors = [
    Color(0xFF1A237E),
    Color(0xFF42A5F5),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
  ];


  static final monthFormat = DateFormat('MMM');

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final providersSnapshot =
        await FirebaseFirestore.instance.collection('providers').get();
    final servicesSnapshot =
        await FirebaseFirestore.instance.collection('services').get();
    final pendingServicesSnapshot =
        await FirebaseFirestore.instance.collection('pending_services').get();
    final bookingsSnapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
    final categoriesSnapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    Map<String, dynamic> processGrowthData(
        List<QueryDocumentSnapshot> docs, String dateField) {
      final Map<String, int> countByMonthYear = {};
      String? firstYear;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey(dateField)) {
          final timestamp = data[dateField] as Timestamp?;
          if (timestamp != null) {
            try {
              final date = DateTime.fromMillisecondsSinceEpoch(
                  timestamp.millisecondsSinceEpoch);
              final monthYear =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}";
              countByMonthYear[monthYear] =
                  (countByMonthYear[monthYear] ?? 0) + 1;
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

    Map<String, int> processCategoryData(
        List<QueryDocumentSnapshot> docs, String categoryField) {
      final Map<String, int> countByCategory = {};
      for (var doc in docs) {
        final category = doc[categoryField] as String? ?? 'Uncategorized';
        countByCategory[category] = (countByCategory[category] ?? 0) + 1;
      }
      return countByCategory;
    }

    List<Map<String, dynamic>> processTopServices(
        List<QueryDocumentSnapshot> bookingDocs,
        List<QueryDocumentSnapshot> serviceDocs) {
      final Map<String, int> bookingsByService = {};
      for (var doc in bookingDocs) {
        final serviceId = doc['serviceId'] as String?;
        if (serviceId != null) {
          bookingsByService[serviceId] =
              (bookingsByService[serviceId] ?? 0) + 1;
        }
      }
      final serviceNames = {
        for (var doc in serviceDocs) doc.id: doc['name'] as String? ?? 'Unknown'
      };
      final sortedServices = bookingsByService.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedServices
          .take(8)
          .map((entry) => {
                'serviceId': entry.key,
                'name': serviceNames[entry.key] ?? 'Unknown',
                'bookings': entry.value,
              })
          .toList();
    }

    Map<String, int> processBookingStatuses(List<QueryDocumentSnapshot> docs) {
      final Map<String, int> countByStatus = {};
      for (var doc in docs) {
        final status = doc['status'] as String? ?? 'Unknown';
        countByStatus[status] = (countByStatus[status] ?? 0) + 1;
      }
      return countByStatus;
    }

    final userGrowthData = processGrowthData(usersSnapshot.docs, 'createdAt');
    final providerGrowthData =
        processGrowthData(providersSnapshot.docs, 'createdAt');

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalProviders': providersSnapshot.docs.length,
      'totalServices': servicesSnapshot.docs.length,
      'totalPendingServices': pendingServicesSnapshot.docs.length,
      'totalBookings': bookingsSnapshot.docs.length,
      'completedBookings': bookingsSnapshot.docs.where((doc) => doc['status'] == 'Completed').length,
      'totalCategories': categoriesSnapshot.docs.length,
      'userGrowth': userGrowthData['data'],
      'userGrowthYear': userGrowthData['year'],
      'providerGrowth': providerGrowthData['data'],
      'providerGrowthYear': providerGrowthData['year'],
      'servicesByCategory': processCategoryData(servicesSnapshot.docs, 'category'),
      'pendingServicesByCategory': processCategoryData(pendingServicesSnapshot.docs, 'category'),
      'topServices': processTopServices(bookingsSnapshot.docs, servicesSnapshot.docs),
      'bookingStatuses': processBookingStatuses(bookingsSnapshot.docs),
    };
  }

  void navigateOrShowMessage(
      BuildContext context, String title, Widget Function() screenBuilder) {
    final allowedItems = [
      'Users',
      'Providers',
      'Services',
      'Bookings',
      'Revenue',
      'Manage Categories'
    ];
    if (allowedItems.contains(title)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => screenBuilder()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have permission to access $title.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: fetchDashboardData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerEffect();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget(snapshot.error);
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoDataWidget();
              }

              final data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(data, context),
                  const SizedBox(height: 24),
                  _buildChartSection(
                      "User Growth",
                      _buildUserGrowthChart(
                          data['userGrowth'], data['userGrowthYear'])),
                  _buildChartSection(
                      "Provider Growth",
                      _buildProviderGrowthChart(
                          data['providerGrowth'], data['providerGrowthYear'])),
                  _buildChartSection(
                      "Services by Category",
                      _buildServicesByCategoryChart(
                          data['servicesByCategory'])),
                  _buildChartSection(
                      "Pending Services",
                      _buildPendingServicesByCategoryChart(
                          data['pendingServicesByCategory'])),
                  _buildChartSection("Top Services",
                      _buildTopServicesChart(data['topServices'])),
                  _buildChartSection("Booking Statuses",
                      _buildBookingStatusesChart(data['bookingStatuses'])),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> data, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Users",
                    "${data['totalUsers']}",
                    Icons.group,
                    chartColors[0],
                    context,
                    () => navigateOrShowMessage(
                        context, "Users", () => UsersScreen()))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildStatCard(
                    "Providers",
                    "${data['totalProviders']}",
                    Icons.work,
                    chartColors[1],
                    context,
                    () => navigateOrShowMessage(
                        context, "Providers", () => ProvidersScreen()))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Services",
                    "${data['totalServices']}",
                    Icons.build,
                    chartColors[2],
                    context,
                    () => navigateOrShowMessage(
                        context, "Services", () => ServicesScreen()))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildStatCard(
                    "Pending",
                    "${data['totalPendingServices']}",
                    Icons.hourglass_empty,
                    chartColors[3],
                    context,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PendingServicesScreen())))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Bookings",
                    "${data['totalBookings']}",
                    Icons.event,
                    chartColors[4],
                    context,
                    () => navigateOrShowMessage(
                        context, "Bookings", () => BookingsScreen()))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildStatCard(
                    "Completed",
                    "${data['completedBookings']}",
                    Icons.check_circle,
                    chartColors[5],
                    context,
                    () => navigateOrShowMessage(
                        context, "Bookings", () => BookingsScreen()))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Categories",
                    "${data['totalCategories']}",
                    Icons.category,
                    chartColors[6],
                    context,
                    () => navigateOrShowMessage(context, "Manage Categories",
                        () => ManageCategoriesScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      BuildContext context, VoidCallback onTap) {
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
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                Icon(Icons.analytics, color: accentColor, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart(
      List<Map<String, dynamic>> userGrowth, String year) {
    if (userGrowth.isEmpty) return _buildEmptyChart();
    final maxCount = userGrowth
        .map((e) => e['count'] as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        Text(
          "Growth in $year",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: primaryColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FlChartLib.BarChart(
            FlChartLib.BarChartData(
              alignment: FlChartLib.BarChartAlignment.spaceAround,
              barGroups: userGrowth.asMap().entries.map((entry) {
                final data = entry.value;
                return FlChartLib.BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    FlChartLib.BarChartRodData(
                      toY: data['count'].toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          chartColors[0],
                          chartColors[0].withOpacity(0.7)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlChartLib.FlTitlesData(
                bottomTitles: FlChartLib.AxisTitles(
                  sideTitles: FlChartLib.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) =>
                        _monthTitles(value, meta, userGrowth),
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
                topTitles: const FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
                rightTitles: const FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
              ),
              gridData: FlChartLib.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCount / 5,
                getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlChartLib.FlBorderData(show: false),
              barTouchData: FlChartLib.BarTouchData(
                touchTooltipData: FlChartLib.BarTouchTooltipData(
                  getTooltipColor: (_) => primaryColor.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthData = userGrowth[group.x.toInt()];
                    final monthName = monthFormat.format(
                        DateTime(monthData['year'], monthData['month']));
                    return FlChartLib.BarTooltipItem(
                      '$monthName\n${rod.toY.toInt()} Users',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
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

  Widget _buildProviderGrowthChart(
      List<Map<String, dynamic>> providerGrowth, String year) {
    if (providerGrowth.isEmpty) return _buildEmptyChart();
    final maxCount = providerGrowth
        .map((e) => e['count'] as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        Text(
          "Growth in $year",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: primaryColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FlChartLib.BarChart(
            FlChartLib.BarChartData(
              alignment: FlChartLib.BarChartAlignment.spaceAround,
              barGroups: providerGrowth.asMap().entries.map((entry) {
                final data = entry.value;
                return FlChartLib.BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    FlChartLib.BarChartRodData(
                      toY: data['count'].toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          chartColors[1],
                          chartColors[1].withOpacity(0.7)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlChartLib.FlTitlesData(
                bottomTitles: FlChartLib.AxisTitles(
                  sideTitles: FlChartLib.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) =>
                        _monthTitles(value, meta, providerGrowth),
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
                topTitles: const FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
                rightTitles: const FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
              ),
              gridData: FlChartLib.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCount / 5,
                getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlChartLib.FlBorderData(show: false),
              barTouchData: FlChartLib.BarTouchData(
                touchTooltipData: FlChartLib.BarTouchTooltipData(
                  getTooltipColor: (_) => primaryColor.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthData = providerGrowth[group.x.toInt()];
                    final monthName = monthFormat.format(
                        DateTime(monthData['year'], monthData['month']));
                    return FlChartLib.BarTooltipItem(
                      '$monthName\n${rod.toY.toInt()} Providers',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
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

    final totalServices = servicesByCategory.values.reduce((a, b) => a + b);
    final sortedCategories = servicesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Map<String, dynamic>> categoryData =
        sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category.value / totalServices * 100).toInt();
      return {
        'name': category.key,
        'count': category.value,
        'percentage': percentage,
        'color': chartColors[index % chartColors.length],
      };
    }).toList();

    return PieChartLib.PieChart(
      dataMap: Map.fromEntries(
          categoryData.map((e) => MapEntry(e['name'], e['count'].toDouble()))),
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      colorList: categoryData.map((e) => e['color'] as Color).toList(),
      chartType: PieChartLib.ChartType.ring,
      centerText: "Services",
      centerTextStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      legendOptions: const PieChartLib.LegendOptions(
        showLegends: true,
        legendPosition: PieChartLib.LegendPosition.bottom,
        showLegendsInRow: true,
        legendTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
      chartValuesOptions: const PieChartLib.ChartValuesOptions(
        showChartValues: true,
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 1,
        chartValueStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      ringStrokeWidth: 20,
      chartRadius: MediaQuery.of(context).size.width / 3,
    );
  }

  Widget _buildPendingServicesByCategoryChart(
      Map<String, int> pendingServicesByCategory) {
    if (pendingServicesByCategory.isEmpty) return _buildEmptyChart();

    final totalPending =
        pendingServicesByCategory.values.reduce((a, b) => a + b);
    final sortedCategories = pendingServicesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Map<String, dynamic>> categoryData =
        sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category.value / totalPending * 100).toInt();
      return {
        'name': category.key,
        'count': category.value,
        'percentage': percentage,
        'color': chartColors[index % chartColors.length],
      };
    }).toList();

    return PieChartLib.PieChart(
      dataMap: Map.fromEntries(
          categoryData.map((e) => MapEntry(e['name'], e['count'].toDouble()))),
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      colorList: categoryData.map((e) => e['color'] as Color).toList(),
      chartType: PieChartLib.ChartType.ring,
      centerText: "Pending",
      centerTextStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      legendOptions: const PieChartLib.LegendOptions(
        showLegends: true,
        legendPosition: PieChartLib.LegendPosition.bottom,
        showLegendsInRow: true,
        legendTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
      chartValuesOptions: const PieChartLib.ChartValuesOptions(
        showChartValues: true,
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 1,
        chartValueStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      ringStrokeWidth: 20,
      chartRadius: MediaQuery.of(context).size.width / 3,
    );
  }

  Widget _buildTopServicesChart(List<Map<String, dynamic>> topServices) {
    if (topServices.isEmpty) return _buildEmptyChart();
    final maxBookings = topServices
        .map((e) => e['bookings'] as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: FlChartLib.BarChart(
            FlChartLib.BarChartData(
              alignment: FlChartLib.BarChartAlignment.spaceAround,
              barGroups: topServices.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                return FlChartLib.BarChartGroupData(
                  x: index,
                  barRods: [
                    FlChartLib.BarChartRodData(
                      toY: service['bookings'].toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          chartColors[index % chartColors.length],
                          chartColors[index % chartColors.length]
                              .withOpacity(0.7)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: const FlChartLib.FlTitlesData(
                bottomTitles: FlChartLib.AxisTitles(
                  sideTitles: FlChartLib.SideTitles(showTitles: false),
                ),
                leftTitles: FlChartLib.AxisTitles(
                  sideTitles: FlChartLib.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: _numberTitles,
                  ),
                ),
                topTitles: FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
                rightTitles: FlChartLib.AxisTitles(
                    sideTitles: FlChartLib.SideTitles(showTitles: false)),
              ),
              gridData: FlChartLib.FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxBookings / 5,
                getDrawingHorizontalLine: (value) => FlChartLib.FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlChartLib.FlBorderData(show: false),
              barTouchData: FlChartLib.BarTouchData(
                touchTooltipData: FlChartLib.BarTouchTooltipData(
                  getTooltipColor: (_) => primaryColor.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final service = topServices[group.x.toInt()];
                    return FlChartLib.BarTooltipItem(
                      '${service['name']}\n${rod.toY.toInt()} Bookings',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: topServices.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chartColors[index % chartColors.length],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    service['name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${service['bookings']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingStatusesChart(Map<String, int> bookingStatuses) {
    if (bookingStatuses.isEmpty) return _buildEmptyChart();
    final dataMap =
        bookingStatuses.map((key, value) => MapEntry(key, value.toDouble()));

    return PieChartLib.PieChart(
      dataMap: dataMap,
      animationDuration: const Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      colorList: chartColors,
      chartType: PieChartLib.ChartType.ring,
      centerText: "Bookings",
      centerTextStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      legendOptions: const PieChartLib.LegendOptions(
        showLegends: true,
        legendPosition: PieChartLib.LegendPosition.bottom,
        showLegendsInRow: true,
        legendTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
      chartValuesOptions: const PieChartLib.ChartValuesOptions(
        showChartValues: true,
        showChartValuesInPercentage: true,
        showChartValuesOutside: true,
        decimalPlaces: 1,
        chartValueStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      ringStrokeWidth: 20,
      chartRadius: MediaQuery.of(context).size.width / 3,
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style:
                TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: TextStyle(color: primaryColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No data available yet',
            style: TextStyle(color: primaryColor, fontSize: 16),
          ),
        ],
      ),
    );
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
            ]),
            const SizedBox(height: 24),
            ...List.generate(
                6,
                (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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

  static Widget _monthTitles(double value, FlChartLib.TitleMeta meta,
      List<Map<String, dynamic>> data) {
    final index = value.toInt();
    if (index >= 0 && index < data.length) {
      final monthData = data[index];
      final monthName =
          monthFormat.format(DateTime(monthData['year'], monthData['month']));
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          monthName,
          style: TextStyle(fontSize: 12, color: primaryColor.withOpacity(0.8)),
        ),
      );
    }
    return const Text('');
  }

  static Widget _numberTitles(double value, FlChartLib.TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        value.toInt().toString(),
        style: TextStyle(fontSize: 12, color: primaryColor.withOpacity(0.8)),
      ),
    );
  }
}

double max(double a, double b) => a > b ? a : b;
