import 'dart:async';

import 'package:disaster_management/config/fcm_config.dart';
import 'package:disaster_management/config/firebase_config.dart';
import 'package:disaster_management/features/disaster_alerts/pages/assistance_help_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/evacuation_screen.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/footerComponent.dart';
import 'package:disaster_management/features/authentication/pages/registration_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:disaster_management/features/authentication/services/auth_service.dart';


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
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return const MainScreen();
          }
          
          return const RegistrationPage();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _setupUserUpdates();
  }

  Future<void> _setupUserUpdates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Initial updates
      await _authService.updateUserLocation(user.uid, context);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _authService.updateFCMToken(user.uid, fcmToken);
      }

      // Listen for FCM token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _authService.updateFCMToken(user.uid, token);
      });

      // Set up periodic location updates
      _locationUpdateTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _authService.updateUserLocation(user.uid, context),
      );
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
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