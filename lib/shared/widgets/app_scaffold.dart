import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String locationName;
  final Color backgroundColor;
  final Widget? drawer;
  final String title;

  const AppScaffold({
    Key? key,
    required this.body,
    required this.locationName,
    required this.backgroundColor,
    this.drawer,
    this.title = "Disaster Alerts",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: drawer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              locationName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        // Rest of your AppBar configuration
      ),
      body: body,
    );
  }
}