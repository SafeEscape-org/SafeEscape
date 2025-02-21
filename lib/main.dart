import 'package:disaster_management/config/fcm_config.dart';
import 'package:disaster_management/config/firebase_config.dart';
import 'package:disaster_management/features/disaster_alerts/pages/assistance_help_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/evacuation_screen.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/footerComponent.dart';
// import 'package:disaster_management/screens/main_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  await FCMConfig.initializeFCM();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Use a modern dark theme
      home: const MainScreen(), // 👈 Set MainScreen as the entry point
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  void onTabSelected(int index) {
    if (currentIndex == index) return;
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          CombinedHomeWeatherComponent(), // 👈 Now HomeScreen contains the weather component
          EmergencyScreen(),
          EvacuationScreen(),
        ],
      ),
      bottomNavigationBar: FooterComponent(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}