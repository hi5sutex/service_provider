import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Global {
  // Static method to create a shimmer widget
  static Widget createShimmer({
    required String text,
    double fontSize = 40.0,
    FontWeight fontWeight = FontWeight.bold,
    double width = 200.0,
    double height = 100.0,
    Color baseColor = Colors.red,
    Color highlightColor = Colors.yellow,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
