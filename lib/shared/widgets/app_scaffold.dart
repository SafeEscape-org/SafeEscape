import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String locationName;
  final bool showDrawer;
  final Widget? drawer;
  final Color backgroundColor;
  
  const AppScaffold({
    Key? key,
    required this.body,
    this.locationName = "Mumbai, India",
    this.showDrawer = true,
    this.drawer,
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: showDrawer ? drawer : null,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Builder(
              builder: (BuildContext context) => HeaderComponent(
                locationName: locationName,
                onMenuPressed: showDrawer ? () {
                  Scaffold.of(context).openDrawer();
                } : () {}, // Provide an empty function instead of null
              ),
            ),
            
            // Page Content
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}