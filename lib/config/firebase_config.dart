import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConfig {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize only core Firebase components
  static Future<void> initializeFirebaseCore() async {
    await Firebase.initializeApp();
    // Only initialize Auth and core services here
  }
  
  // Complete the rest of Firebase initialization
  static Future<void> completeFirebaseInitialization() async {
    // Initialize Firestore, Storage, and other non-critical services
    await Future.wait([
      _initializeFirestore(),
      _initializeStorage(),
      // Other services
    ]);
  }
  
  // Original method for backward compatibility
  static Future<void> initializeFirebase() async {
    await initializeFirebaseCore();
    await completeFirebaseInitialization();
  }
  
  // Helper methods
  static Future<void> _initializeFirestore() async {
    // Firestore initialization
  }
  
  static Future<void> _initializeStorage() async {
    // Storage initialization
  }
}
