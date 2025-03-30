import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_provider/User%20Panel/Usertheme.dart';


class CustomSnackBar extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String type; // 'success', 'error', etc.

  const CustomSnackBar({
    super.key,
    required this.message,
    this.icon,
    this.type = 'success',
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and icon based on type
    final Color backgroundColor = type == 'success'
        ? const Color(0xFFEAF3EC) // Solid light green background for success
        : UserTheme.errorTextColor; // Solid crimson red background for error

    final Color borderColor = type == 'success'
        ? const Color(0xFFD5E0D7) // Slightly darker green border for success
        : UserTheme.errorTextColor; // Crimson red border for error

    final Color iconColor = type == 'success'
        ? UserTheme.successColor // Forest Green for success icon
        : UserTheme.errorTextColor; // Crimson Red for error icon

    final IconData displayIcon = icon ??
        (type == 'success'
            ? FontAwesomeIcons.checkCircle // Checkmark for success
            : FontAwesomeIcons.exclamationCircle); // Warning for error

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            displayIcon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: UserTheme.primaryTextColor, // Dark text (Dark Navy Blue)
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}