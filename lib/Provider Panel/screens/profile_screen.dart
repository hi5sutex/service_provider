import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_provider/Provider%20Panel/CustomSnackBar.dart';
import 'package:service_provider/Provider%20Panel/EarningsPage.dart';
import 'package:service_provider/User%20Panel/user_login.dart';
import 'package:service_provider/Provider%20Panel/screens/edit_profile.dart';
import 'package:service_provider/Provider%20Panel/screens/manage_services.dart';
import 'package:service_provider/Provider%20Panel/screens/portfolio.dart';
import 'package:service_provider/Provider%20Panel/screens/provider_settings.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProviderProfile extends StatefulWidget {
  const ProviderProfile({Key? key}) : super(key: key);

  @override
  _ProviderProfileState createState() => _ProviderProfileState();
}

class _ProviderProfileState extends State<ProviderProfile> {
  final String providerId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Random _random = Random();
  late Future<Map<String, dynamic>> _providerInfoFuture;
  late ScrollController _scrollController;
  double _opacity = 0.0;
  late List<Map<String, dynamic>> _dotProperties;

  @override
  void initState() {
    super.initState();
    _providerInfoFuture = _getProviderInfo();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateOpacity);

    _dotProperties = List.generate(20, (index) => {
      'top': index < 10 ? _random.nextDouble() * 140 : null,
      'bottom': index >= 10 ? _random.nextDouble() * 140 : null,
      'leftFactor': index % 2 == 0 ? _random.nextDouble() : null,
      'rightFactor': index % 2 == 1 ? _random.nextDouble() : null,
      'size': _random.nextDouble() * 10 + 4,
      'opacity': _random.nextDouble() * 0.2 + 0.1,
    });
  }

  void _updateOpacity() {
    final offset = _scrollController.offset;
    const maxOffset = 300.0 - kToolbarHeight;
    const startFadeAt = 200.0;
    setState(() {
      _opacity = offset <= startFadeAt
          ? 0.0
          : ((offset - startFadeAt) / (maxOffset - startFadeAt)).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout failed. Please try again.")),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getProviderInfo() async {
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(providerId)
        .get();
    return providerDoc.data() as Map<String, dynamic>? ?? {};
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _providerInfoFuture = _getProviderInfo(); // Re-fetch provider info
    });
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const CustomSnackBar(
          message: 'Coming Soon!',
          type: 'success', // Use success type for informational message
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // Transparent to let CustomSnackBar handle the background
        elevation: 0,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final halfWidth = MediaQuery.of(context).size.width / 2;
    final fixedDots = _dotProperties.map((dot) => Positioned(
      top: dot['top'] as double?,
      bottom: dot['bottom'] as double?,
      left: dot['leftFactor'] != null ? (dot['leftFactor'] as double) * halfWidth : null,
      right: dot['rightFactor'] != null ? (dot['rightFactor'] as double) * halfWidth : null,
      child: Container(
        width: dot['size'] as double,
        height: dot['size'] as double,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ProviderTheme.accentColor.withOpacity(dot['opacity'] as double),
        ),
      ),
    )).toList();

    return Scaffold(
      backgroundColor: ProviderTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: ProviderTheme.accentColor,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: ProviderTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      ...fixedDots,
                      Positioned(
                        bottom: -50,
                        left: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ProviderTheme.accentColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ProviderTheme.accentColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _providerInfoFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: ProviderTheme.accentColor,
                              ),
                            );
                          }
                          final providerInfo = snapshot.data!;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 50),
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: CachedNetworkImageProvider(
                                    providerInfo['profileImage'] ?? 'https://avatar.iran.liara.run/public',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  providerInfo['name'] ?? 'John Doe',
                                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                                    color: ProviderTheme.onPrimaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  providerInfo['email'] ?? 'example@example.com',
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: ProviderTheme.onPrimaryTextColor.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    providerInfo['bio'] ?? 'This Is My Bio',
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: ProviderTheme.onPrimaryTextColor.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              title: FutureBuilder<Map<String, dynamic>>(
                future: _providerInfoFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final providerInfo = snapshot.data!;
                  return Opacity(
                    opacity: _opacity,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(
                            providerInfo['profileImage'] ?? 'https://avatar.iran.liara.run/public',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          providerInfo['name'] ?? 'John Doe',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: ProviderTheme.onPrimaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              backgroundColor: ProviderTheme.primaryColor,
              elevation: 4,
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _providerInfoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ProviderTheme.accentColor,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        snapshot.hasError ? 'Error loading provider info.' : 'No provider data found.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildOptionList(context),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildListTile(context, Icons.work, 'Manage Services', () => _navigateTo(context, ManageServices())),
          _buildListTile(context, Icons.account_balance_wallet, 'Earnings', () => _navigateTo(context, EarningsPage())),
          _buildListTile(context, Icons.analytics_outlined, 'Analytics', () => _showComingSoonSnackBar()),
          _buildListTile(context, Icons.perm_media, 'Portfolio', () => _showComingSoonSnackBar()),
          _buildListTile(context, Icons.edit, 'Edit Profile', () => _navigateTo(context, EditProfile())),
          _buildListTile(context, Icons.settings, 'Settings', () => _showComingSoonSnackBar()),
          _buildListTile(context, Icons.logout, 'Logout', () => _logout(context), iconColor: ProviderTheme.canceledColor),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? iconColor}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: ProviderTheme.surfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ProviderTheme.primaryColor.withOpacity(0.3), ProviderTheme.secondaryColor.withOpacity(.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ProviderTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: ProviderTheme.primaryColor.withOpacity(0.7), size: 24),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: ProviderTheme.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: ProviderTheme.secondaryTextColor,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}