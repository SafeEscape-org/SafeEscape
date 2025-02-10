import 'package:disaster_management/config/fcm_config.dart';
import 'package:disaster_management/config/firebase_config.dart';
import 'package:disaster_management/features/disaster_alerts/pages/home_screen.dart';
import 'package:flutter/material.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Required before async initialization
  // Initialize Firebase and FCM
  await FirebaseConfig.initializeFirebase();
  await FCMConfig.initializeFCM();
   runApp(MaterialApp(
    home: CombinedHomeWeatherComponent(),
  ));
}

