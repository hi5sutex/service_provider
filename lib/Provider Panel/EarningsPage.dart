import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';

class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedFilter = 'Pending'; // Default filter
  final List<Map<String, dynamic>> filterOptions = [
    // {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'Pending', 'icon': Icons.pending_actions},
    {'label': 'Completed', 'icon': Icons.check_circle},
  ];

  // Time period filter options with icons
  String _selectedPeriod = 'This Month';
  final List<Map<String, dynamic>> periodOptions = [
    {'label': 'This Week', 'icon': Icons.calendar_view_week},
    {'label': 'This Month', 'icon': Icons.calendar_view_month},
    {'label': 'Last 3 Months', 'icon': Icons.calendar_today},
    {'label': 'This Year', 'icon': Icons.calendar_view_day},
    {'label': 'All Time', 'icon': Icons.access_time},
  ];

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  // Define a list of colors for services - using a more professional color palette
  final List<Color> colorList = [
    ProviderTheme.primaryColor,
    ProviderTheme.secondaryColor,
    ProviderTheme.accentColor,
    ProviderTheme.successColor,
    ProviderTheme.warningColor,
    ProviderTheme.errorTextColor,
    ProviderTheme.ongoingColor,
    ProviderTheme.completedColor,
    ProviderTheme.canceledColor,
    Color(0xFF455A64), // Blue Grey
    Color(0xFF5D4037), // Brown
    Color(0xFF00796B), // Dark Teal
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: ProviderTheme.backgroundColor,
        body: Center(
          child: Text(
            'Please log in to view earnings',
            style: ProviderTheme.themeData.textTheme.bodyLarge,
          ),
        ),
      );
    }
    final String providerId = user.uid;

    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Earnings Dashboard',
          style: ProviderTheme.themeData.appBarTheme.titleTextStyle,

        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ProviderTheme.primaryGradient,
          ),
        ),
        elevation: ProviderTheme.themeData.appBarTheme.elevation,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.refresh, color: ProviderTheme.onPrimaryTextColor),
          //   onPressed: () {
          //     setState(() {});
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.help_outline, color: ProviderTheme.onPrimaryTextColor),
            padding: EdgeInsets.only(right: 8),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Earnings Help', style: ProviderTheme.themeData.textTheme.titleLarge),
                  content: Text('This dashboard shows your earnings summary and transaction history.'),
                  actions: [
                    TextButton(
                      child: Text('OK', style: TextStyle(color: ProviderTheme.primaryColor)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date range and summary
            Container(
              decoration: const BoxDecoration(
                gradient: ProviderTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Period filter in header
                  _buildFilterMenu(
                    context: context,
                    currentValue: _selectedPeriod,
                    options: periodOptions,
                    iconColor: ProviderTheme.onPrimaryTextColor,
                    textColor: ProviderTheme.onPrimaryTextColor,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Summary cards
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('earnings')
                        .doc(providerId)
                        .collection('records')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSummaryShimmer();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptySummary();
                      }

                      // Calculate totals
                      double totalEarnings = 0.0;
                      double completedEarnings = 0.0;

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final amount = (data['serviceAmount'] as num?)?.toDouble() ?? 0.0;
                        totalEarnings += amount;
                        if (data['earningStatus'] == 'Completed') {
                          completedEarnings += amount;
                        }
                      }

                      double pendingEarnings = totalEarnings - completedEarnings;

                      return _buildSummaryCards(
                        totalEarnings: totalEarnings,
                        completedEarnings: completedEarnings,
                        pendingEarnings: pendingEarnings,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  _buildSectionHeader('Earnings Overview'),
                  const SizedBox(height: 16),

                  // Pie Chart container
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: ProviderTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ProviderTheme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Earnings by Service',
                              style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(fontSize: 16),
                            ),
                            Icon(Icons.pie_chart, color: ProviderTheme.primaryColor),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPieChartWithDetails(providerId),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Transactions'),
                      _buildFilterMenu(
                        context: context,
                        currentValue: _selectedFilter,
                        options: filterOptions,
                        iconColor: ProviderTheme.primaryColor,
                        textColor: ProviderTheme.primaryTextColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transactions list
                  _buildTransactionsList(providerId),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterMenu({
    required BuildContext context,
    required String currentValue,
    required List<Map<String, dynamic>> options,
    required Function(String) onChanged,
    required Color iconColor,
    required Color textColor,
  }) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onChanged,
      offset: const Offset(0, 50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForValue(currentValue, options),
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              currentValue,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: iconColor,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return options.map((option) {
          return PopupMenuItem<String>(
            value: option['label'],
            child: Row(
              children: [
                Icon(option['icon'], color: ProviderTheme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(option['label']),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  IconData _getIconForValue(String value, List<Map<String, dynamic>> options) {
    for (var option in options) {
      if (option['label'] == value) {
        return option['icon'];
      }
    }
    return Icons.error; // Fallback
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(fontSize: 18),
    );
  }

  Widget _buildEmptySummary() {
    return Column(
      children: [
        _buildMainEarningsCard(0.0),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricCard('Completed', 0.0, Icons.check_circle, ProviderTheme.successColor),
            const SizedBox(width: 10),
            _buildMetricCard('Pending', 0.0, Icons.pending_actions, ProviderTheme.warningColor),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards({
    required double totalEarnings,
    required double completedEarnings,
    required double pendingEarnings,
  }) {
    return Column(
      children: [
        _buildMainEarningsCard(totalEarnings),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricCard('Completed', completedEarnings, Icons.check_circle, ProviderTheme.successColor),
            const SizedBox(width: 10),
            _buildMetricCard('Pending', pendingEarnings, Icons.pending_actions, ProviderTheme.warningColor),
          ],
        ),
      ],
    );
  }

  Widget _buildMainEarningsCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ProviderTheme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
              color: ProviderTheme.primaryTextColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: ProviderTheme.themeData.textTheme.displayMedium?.copyWith(
              color: ProviderTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ProviderTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedPeriod,
              style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                color: ProviderTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ProviderTheme.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                    color: ProviderTheme.primaryTextColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartWithDetails(String providerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .doc(providerId)
          .collection('records')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartShimmer();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 48,
                  color: ProviderTheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No earnings data available',
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        Map<String, double> serviceEarnings = {};
        double totalEarnings = 0.0;
        List<Future<void>> futures = [];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String bookingId = doc.id;
          final double amount = (data['serviceAmount'] as num?)?.toDouble() ?? 0.0;
          totalEarnings += amount;

          futures.add(
            FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .get()
                .then((bookingSnapshot) {
              if (bookingSnapshot.exists) {
                final bookingData = bookingSnapshot.data() as Map<String, dynamic>?;
                final String serviceId = bookingData?['serviceId'] ?? 'Unknown';
                return FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .get()
                    .then((serviceSnapshot) {
                  if (serviceSnapshot.exists) {
                    final serviceData = serviceSnapshot.data() as Map<String, dynamic>?;
                    String serviceName = serviceData?['name'] ?? 'Unknown Service';
                    serviceEarnings[serviceName] = (serviceEarnings[serviceName] ?? 0.0) + amount;
                  }
                });
              }
              return Future.value();
            }).catchError((error) {
              print('Error fetching service: $error');
            }),
          );
        }

        return FutureBuilder(
          future: Future.wait(futures),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return _buildChartShimmer();
            }
            if (serviceEarnings.isEmpty) {
              return Container(
                height: 300,
                alignment: Alignment.center,
                child: Text(
                  'No service data available',
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
              );
            }

            // Sort services by earnings in descending order
            List<MapEntry<String, double>> sortedServiceEarnings = serviceEarnings.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // Rebuild serviceEarnings and serviceNames in sorted order
            Map<String, double> sortedServiceEarningsMap = Map.fromEntries(sortedServiceEarnings);
            List<String> serviceNames = sortedServiceEarnings.map((entry) => entry.key).toList();

            // Dynamically assign colors to services in sorted order
            List<Color> assignedColors = [];
            for (int i = 0; i < serviceNames.length; i++) {
              assignedColors.add(colorList[i % colorList.length]);
            }

            // Calculate percentages
            Map<String, double> servicePercentages = {};
            sortedServiceEarningsMap.forEach((service, amount) {
              servicePercentages[service] = (amount / totalEarnings) * 100;
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 280, // Adjusted height for chart
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: PieChart(
                    dataMap: sortedServiceEarningsMap, // Use sorted map for the chart
                    animationDuration: const Duration(milliseconds: 800),
                    colorList: assignedColors,
                    chartType: ChartType.ring,
                    centerText: "Services",
                    legendOptions: LegendOptions(
                      showLegends: false,
                    ),
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValues: false, // Hide percentages in chart
                      showChartValuesInPercentage: false,
                    ),
                    ringStrokeWidth: 30,
                    chartRadius: MediaQuery.of(context).size.width / 1.7,
                    gradientList: serviceNames.map((service) {
                      final index = serviceNames.indexOf(service);
                      final color = assignedColors[index % assignedColors.length];
                      return [
                        color,
                        color.withOpacity(0.8),
                      ];
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Service details with percentages only, in sorted order
                ...serviceNames.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  final percentage = servicePercentages[service] ?? 0.0;
                  final color = assignedColors[index % assignedColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service,
                            style: ProviderTheme.themeData.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${percentage.toStringAsFixed(1)}%)',
                          style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsList(String providerId) {
    Stream<QuerySnapshot> stream;
    if (_selectedFilter == 'All') {
      stream = FirebaseFirestore.instance
          .collection('earnings')
          .doc(providerId)
          .collection('records')
          .where('earningStatus', whereIn: ['Pending', 'Completed'])
          .orderBy('paymentAt', descending: true)
          .limit(10)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('earnings')
          .doc(providerId)
          .collection('records')
          .where('earningStatus', isEqualTo: _selectedFilter)
          .orderBy('paymentAt', descending: true)
          .limit(10)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTransactionShimmer();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: ProviderTheme.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No earnings found for $_selectedFilter',
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final earningData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final String bookingId = snapshot.data!.docs[index].id;

            return EarningsCard(
              earningData: earningData,
              bookingId: bookingId,
              currencyFormat: currencyFormat,
              onViewDetails: () => _showDetailsBottomSheet(context, earningData, bookingId),
            );
          },
        );
      },
    );
  }

  void _showDetailsBottomSheet(BuildContext context, Map<String, dynamic> earningData, String bookingId) {
    final double serviceAmount = (earningData['serviceAmount'] as num?)?.toDouble() ?? 0.0;
    final double taxAmount = (earningData['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final double platformFee = (earningData['platformFee'] as num?)?.toDouble() ?? 0.0;
    final double paymentAmount = (earningData['paymentAmount'] as num?)?.toDouble() ?? 0.0;
    final String earningStatus = earningData['earningStatus'] ?? 'Unknown';
    final Timestamp? paymentAt = earningData['paymentAt'] as Timestamp?;
    final String paymentDate = paymentAt != null
        ? "${paymentAt.toDate().day} ${_getMonthName(paymentAt.toDate().month)} ${paymentAt.toDate().year}"
        : 'Unknown Date';
    final String paymentTime = paymentAt != null ? _formatTime(paymentAt.toDate()) : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: ProviderTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Transaction Details',
                style: ProviderTheme.themeData.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            _buildAmountRow('Booking ID', bookingId, isLabel: true),
            const SizedBox(height: 8),
            _buildAmountRow('Pay by User', currencyFormat.format(paymentAmount)),
            _buildAmountRow('Tax (11%)', currencyFormat.format(taxAmount)),
            _buildAmountRow('Platform Fee', currencyFormat.format(platformFee)),
            const Divider(height: 20),
            _buildAmountRow('Received Amount', currencyFormat.format(serviceAmount), isTotal: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: ProviderTheme.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  paymentDate,
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  paymentTime,
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ProviderTheme.themeData.elevatedButtonTheme.style,
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              2,
                  (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 1 ? 10 : 0),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartShimmer() {
    return Shimmer.fromColors(
      baseColor: ProviderTheme.dividerColor,
      highlightColor: ProviderTheme.backgroundColor,
      child: Container(
        height: 350,
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 10, width: 100, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 10, width: 150, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 10, width: 120, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionShimmer() {
    return Shimmer.fromColors(
      baseColor: ProviderTheme.dividerColor,
      highlightColor: ProviderTheme.backgroundColor,
      child: Column(
        children: List.generate(
          5,
              (index) => Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class EarningsCard extends StatelessWidget {
  final Map<String, dynamic> earningData;
  final String bookingId;
  final NumberFormat currencyFormat;
  final VoidCallback onViewDetails;

  const EarningsCard({
    required this.earningData,
    required this.bookingId,
    required this.currencyFormat,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('bookings').doc(bookingId).get(),
      builder: (context, snapshot) {
        String serviceName = 'Loading...';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
          final String serviceId = bookingData?['serviceId'] ?? 'Unknown';
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('services').doc(serviceId).get(),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.done && serviceSnapshot.hasData) {
                final serviceData = serviceSnapshot.data!.data() as Map<String, dynamic>?;
                serviceName = serviceData?['name'] ?? 'Unknown Service';
              }
              return _buildCard(context, serviceName);
            },
          );
        }
        return _buildCard(context, serviceName);
      },
    );
  }

  Widget _buildCard(BuildContext context, String serviceName) {
    final double serviceAmount = (earningData['serviceAmount'] as num?)?.toDouble() ?? 0.0;
    final String earningStatus = earningData['earningStatus'] ?? 'Unknown';
    final Timestamp? paymentAt = earningData['paymentAt'] as Timestamp?;
    final String paymentDate = paymentAt != null
        ? "${paymentAt.toDate().day} ${_getMonthName(paymentAt.toDate().month)} ${paymentAt.toDate().year}"
        : 'Unknown Date';

    Color statusColor = earningStatus == 'Completed' ? ProviderTheme.successColor : ProviderTheme.warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ProviderTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $bookingId',
                        style: ProviderTheme.themeData.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    earningStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Received Amount',
                  style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(serviceAmount),
                  style: ProviderTheme.themeData.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ProviderTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: ProviderTheme.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  paymentDate,
                  style: ProviderTheme.themeData.textTheme.bodyMedium,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onViewDetails,
                  child: Text(
                    'View Details',
                    style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
                      color: ProviderTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

Widget _buildAmountRow(String label, String value, {bool isTotal = false, bool isLabel = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isLabel ? ProviderTheme.secondaryTextColor : null,
          ),
        ),
        Text(
          value,
          style: ProviderTheme.themeData.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? ProviderTheme.primaryColor : ProviderTheme.primaryTextColor,
          ),
        ),
      ],
    ),
  );
}