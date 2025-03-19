import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disaster_management/config/fcm_config.dart';
import 'package:disaster_management/config/firebase_config.dart';
import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/features/disaster_alerts/pages/assistance_help_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:disaster_management/features/disaster_alerts/pages/evacuation_screen.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/footerComponent.dart';
import 'package:disaster_management/features/authentication/pages/registration_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:disaster_management/features/authentication/services/auth_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:disaster_management/services/socket_service.dart';

 void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FirebaseConfig.initializeFirebase();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    await FCMConfig.initializeFCM();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SocketService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  
  await Future.delayed(const Duration(milliseconds: 500));
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SocketService().navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => Consumer<SocketService>(
          builder: (context, socketService, child) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData) {
                  return const MainScreen();
                }

                return const RegistrationPage();
              },
            );
          },
        ),
        '/home': (context) => const MainScreen(),
      },
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
    _initializeSocket();
  }

  void _initializeSocket() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      socketService.socket.emit('user_connected', {
        'userId': user.uid,
        'email': user.email,
      });
    }
  }

  Future<void> _setupUserUpdates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      //update user location as user mmust get his latest location updates

      // Initial location update
      await _authService.updateUserLocation(user.uid, context);

      // Check and update FCM token if needed
      bool tokenUpdated = await _authService.checkAndUpdateFCMToken(user.uid);
      
      // Show alert if token was updated
      if (tokenUpdated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings updated'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    
      //periodic location updates for user nearlest areas updates
      // Update location less frequently to save battery
      _locationUpdateTimer = Timer.periodic(
        const Duration(minutes: 30), // Changed from 15 to 30 minutes
        (_) => _authService.updateUserLocation(user.uid, context),
      );
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.disconnect();
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
