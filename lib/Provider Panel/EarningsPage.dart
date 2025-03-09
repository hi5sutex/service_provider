import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedFilter = 'All'; // Default filter
  final List<Map<String, dynamic>> filterOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive},
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

  final Color primaryColor = Color(0xFF060644);
  final Color secondaryColor = Colors.white;
  final Color accentColor =
      Color(0xFF4355B9); // A slightly lighter shade for accents
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  // Define a list of colors for services - using a more professional color palette
  final List<Color> colorList = [
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

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view earnings')),
      );
    }
    final String providerId = user.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Earnings Dashboard',
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: secondaryColor),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: secondaryColor),
            onPressed: () {
              // Show help dialog or info
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Earnings Help',
                      style: TextStyle(color: primaryColor)),
                  content: Text(
                      'This dashboard shows your earnings summary and transaction history.'),
                  actions: [
                    TextButton(
                      child: Text('OK', style: TextStyle(color: primaryColor)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Making the whole page scrollable
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with date range and summary
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  // Period filter in header
                  _buildFilterMenu(
                    context: context,
                    currentValue: _selectedPeriod,
                    options: periodOptions,
                    iconColor: secondaryColor,
                    textColor: secondaryColor,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),

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
                      int totalBookings = snapshot.data!.docs.length;

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final amount =
                            (data['serviceAmount'] as num?)?.toDouble() ?? 0.0;
                        totalEarnings += amount;
                        if (data['earningStatus'] == 'Completed') {
                          completedEarnings += amount;
                        }
                      }

                      double pendingEarnings =
                          totalEarnings - completedEarnings;
                      double avgEarning = totalBookings > 0
                          ? totalEarnings / totalBookings
                          : 0.0;

                      return _buildSummaryCards(
                        totalEarnings: totalEarnings,
                        completedEarnings: completedEarnings,
                        pendingEarnings: pendingEarnings,
                        avgEarning: avgEarning,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content Area
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  _buildSectionHeader('Earnings Overview'),
                  SizedBox(height: 16),

                  // Pie Chart container
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Icon(Icons.pie_chart, color: primaryColor),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildPieChart(providerId),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Recent Transactions'),

                      // Status filter menu
                      _buildFilterMenu(
                        context: context,
                        currentValue: _selectedFilter,
                        options: filterOptions,
                        iconColor: primaryColor,
                        textColor: primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Transactions list
                  _buildTransactionsList(providerId),
                ],
              ),
            ),

            SizedBox(height: 24),
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
      offset: Offset(0, 50),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            SizedBox(width: 8),
            Text(
              currentValue,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
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
                Icon(option['icon'], color: primaryColor, size: 20),
                SizedBox(width: 10),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _buildEmptySummary() {
    return Column(
      children: [
        _buildMainEarningsCard(0.0),
        SizedBox(height: 20),
        Row(
          children: [
            _buildMetricCard(
                'Completed', 0.0, Icons.check_circle, Colors.green),
            SizedBox(width: 10),
            _buildMetricCard(
                'Pending', 0.0, Icons.pending_actions, Colors.orange),
            SizedBox(width: 10),
            _buildMetricCard('Average', 0.0, Icons.trending_up, accentColor),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards({
    required double totalEarnings,
    required double completedEarnings,
    required double pendingEarnings,
    required double avgEarning,
  }) {
    return Column(
      children: [
        _buildMainEarningsCard(totalEarnings),
        SizedBox(height: 20),
        Row(
          children: [
            _buildMetricCard('Completed', completedEarnings, Icons.check_circle,
                Colors.green),
            SizedBox(width: 10),
            _buildMetricCard('Pending', pendingEarnings, Icons.pending_actions,
                Colors.orange),
            SizedBox(width: 10),
            _buildMetricCard(
                'Average', avgEarning, Icons.trending_up, accentColor),
          ],
        ),
      ],
    );
  }

  Widget _buildMainEarningsCard(double amount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedPeriod,
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(String providerId) {
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
            height: 250,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No earnings data available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        Map<String, double> serviceEarnings = {};
        List<Future<void>> futures = [];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String bookingId = doc.id;
          final double amount =
              (data['serviceAmount'] as num?)?.toDouble() ?? 0.0;

          futures.add(
            FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .get()
                .then((bookingSnapshot) {
              if (bookingSnapshot.exists) {
                final bookingData =
                    bookingSnapshot.data() as Map<String, dynamic>?;
                final String serviceId = bookingData?['serviceId'] ?? 'Unknown';
                return FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .get()
                    .then((serviceSnapshot) {
                  if (serviceSnapshot.exists) {
                    final serviceData =
                        serviceSnapshot.data() as Map<String, dynamic>?;
                    String serviceName =
                        serviceData?['name'] ?? 'Unknown Service';
                    serviceEarnings[serviceName] =
                        (serviceEarnings[serviceName] ?? 0.0) + amount;
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
              return Center(child: Text('No service data available'));
            }

            // Dynamically assign colors to services
            List<Color> assignedColors = [];
            List<String> serviceNames = serviceEarnings.keys.toList();
            for (int i = 0; i < serviceNames.length; i++) {
              assignedColors.add(colorList[i % colorList.length]);
            }

            return Container(
              height: 300,
              padding: EdgeInsets.symmetric(vertical: 16),
              child: PieChart(
                dataMap: serviceEarnings,
                animationDuration: Duration(milliseconds: 800),
                chartLegendSpacing: 32,
                colorList: assignedColors,
                chartType: ChartType.ring,
                centerText: "Services",
                legendOptions: LegendOptions(
                  showLegends: true,
                  legendPosition: LegendPosition.bottom,
                  showLegendsInRow: false,
                  legendTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                chartValuesOptions: ChartValuesOptions(
                  showChartValuesInPercentage: true,
                  showChartValuesOutside: true,
                  decimalPlaces: 1,
                  chartValueStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ringStrokeWidth: 25,
                chartRadius: MediaQuery.of(context).size.width / 2.5,
                gradientList: serviceNames.map((service) {
                  final index = serviceNames.indexOf(service);
                  final color = assignedColors[index % assignedColors.length];
                  return [
                    color,
                    color.withOpacity(0.8),
                  ];
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsList(String providerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedFilter == 'All'
          ? FirebaseFirestore.instance
              .collection('earnings')
              .doc(providerId)
              .collection('records')
              .orderBy('paymentAt', descending: true)
              .limit(10)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('earnings')
              .doc(providerId)
              .collection('records')
              .where('earningStatus', isEqualTo: _selectedFilter)
              .orderBy('paymentAt', descending: true)
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTransactionShimmer();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
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
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No earnings found for $_selectedFilter',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final earningData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final String bookingId = snapshot.data!.docs[index].id;

            return EarningsCard(
              earningData: earningData,
              bookingId: bookingId,
              currencyFormat: currencyFormat,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            );
          },
        );
      },
    );
  }

  // Shimmer loading effects
  Widget _buildSummaryShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  height: 70,
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 300,
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 10,
              width: 100,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Container(
              height: 10,
              width: 150,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Container(
              height: 10,
              width: 120,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          5,
          (index) => Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            height: 120,
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
}

class EarningsCard extends StatelessWidget {
  final Map<String, dynamic> earningData;
  final String bookingId;
  final NumberFormat currencyFormat;
  final Color primaryColor;
  final Color secondaryColor;

  const EarningsCard({
    required this.earningData,
    required this.bookingId,
    required this.currencyFormat,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get(),
      builder: (context, snapshot) {
        String serviceName = 'Loading...';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
          final String serviceId = bookingData?['serviceId'] ?? 'Unknown';
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('services')
                .doc(serviceId)
                .get(),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.done &&
                  serviceSnapshot.hasData) {
                final serviceData =
                    serviceSnapshot.data!.data() as Map<String, dynamic>?;
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
    final double serviceAmount =
        (earningData['serviceAmount'] as num?)?.toDouble() ?? 0.0;
    final double taxAmount =
        (earningData['taxAmount'] as num?)?.toDouble() ?? 0.0;
    final double platformFee =
        (earningData['platformFee'] as num?)?.toDouble() ?? 0.0;
    final double paymentAmount =
        (earningData['paymentAmount'] as num?)?.toDouble() ?? 0.0;
    final String earningStatus = earningData['earningStatus'] ?? 'Unknown';
    final Timestamp? paymentAt = earningData['paymentAt'] as Timestamp?;
    final String paymentDate = paymentAt != null
        ? "${paymentAt.toDate().day} ${_getMonthName(paymentAt.toDate().month)} ${paymentAt.toDate().year}"
        : 'Unknown Date';
    final String paymentTime =
        paymentAt != null ? _formatTime(paymentAt.toDate()) : '';

    // Get status color
    Color statusColor =
        earningStatus == 'Completed' ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: $bookingId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAmountRow('Pay by User', paymentAmount),
                _buildAmountRow('Tax (11%)', taxAmount),
                _buildAmountRow('Platform Fee', platformFee),
                Divider(height: 20),
                _buildAmountRow(
                  'Received Amount',
                  serviceAmount,
                  isTotal: true,
                  valueColor: primaryColor,
                ),

                SizedBox(height: 10),

                // Date information
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      paymentDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    Text(
                      paymentTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // View Details button
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      // Navigate to a detailed view or show more details
                    },
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isTotal ? primaryColor : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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

// Math utility for substring min
class Math {
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
