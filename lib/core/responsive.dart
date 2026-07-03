import 'package:flutter/material.dart';

extension ResponsiveExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  double responsiveValue(double value, {double minValue = 10, double maxValue = double.infinity}) {
    final scale = (screenWidth / 375.0).clamp(minValue / value, maxValue / value);
    return value * scale;
  }

  EdgeInsets get pagePadding {
    final horizontal = screenWidth < 400 ? 16.0 : screenWidth < 800 ? 24.0 : 32.0;
    final vertical = screenWidth < 400 ? 14.0 : 18.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  Widget responsiveBody({required Widget child, double maxWidth = 760}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: pagePadding,
          child: child,
        ),
      ),
    );
  }
}
