import 'package:flutter/material.dart';

class AppColors {
  static const primaryColor = Color(0xFF007AFF);
  static const accentColor = Color(0xFF5AC8FA);
  static const backgroundColor = Color(0xFFF2F6FC);
  static const textColor = Color(0xFF333333);
  static const shadowColor = Color(0x1A000000);
  static const double borderRadius = 20.0;  // Added border radius constant

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primaryColor, accentColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}