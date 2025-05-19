import 'package:flutter/material.dart';

class NavigationItem {
  final IconData icon;
  final String title;
  final String? badge;
  final String? route;
  final Color? iconColor;
  final Color? badgeColor;
  final bool hasAlert;
  final AlertLevel alertLevel;
  
  NavigationItem({
    required this.icon,
    required this.title,
    this.badge,
    this.route,
    this.iconColor,
    this.badgeColor,
    this.hasAlert = false,
    this.alertLevel = AlertLevel.none,
  });
}

enum AlertLevel {
  none,
  low,
  medium,
  high,
}