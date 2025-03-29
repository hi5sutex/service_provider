import 'package:flutter/material.dart';
import 'package:service_provider/Provider%20Panel/provider_theme.dart';

class BookingCategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const BookingCategoryCard({
    required this.category,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shape = ProviderTheme.themeData.cardTheme.shape as RoundedRectangleBorder?;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: shape,
        color: ProviderTheme.cardHighlightColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: shape?.borderRadius ?? BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                category,
                style: ProviderTheme.themeData.textTheme.titleLarge?.copyWith(
                  color: ProviderTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: ProviderTheme.themeData.textTheme.displayMedium?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}