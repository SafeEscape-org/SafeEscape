import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:disaster_management/services/location_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> emergencyContacts,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      debugPrint("Starting user registration for: $email");

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
          "User created successfully with ID: ${userCredential.user?.uid}");

      // Get FCM token for notifications
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint("FCM token obtained: ${fcmToken?.substring(0, 10)}...");
      } catch (e) {
        debugPrint("Failed to get FCM token: $e");
        // Continue without FCM token
      }

      // Create user document with additional info
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
        'emergencyContacts': emergencyContacts,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add FCM token if available
      if (fcmToken != null) {
        userData['fcmTokens'] = [
          {
            'token': fcmToken,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ];
      }

      debugPrint("Saving user data to Firestore...");
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);
      debugPrint("User data saved successfully");

      return userCredential;
    } catch (e) {
      debugPrint("Registration error: $e");
      throw _handleAuthError(e);
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Better error handling
  Exception _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception('This email is already registered');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'operation-not-allowed':
          return Exception('Email/Password sign in is not enabled');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'user-disabled':
          return Exception('This account has been disabled');
        case 'user-not-found':
          return Exception('No account found with this email');
        case 'wrong-password':
          return Exception('Incorrect password');
        default:
          return Exception('Authentication failed: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred');
  }

  Future<void> updateUserLocation(String uid, BuildContext context) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        debugPrint("User not authenticated when trying to update location");
        throw Exception('User not authenticated');
      }

      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData == null) {
        throw Exception('Failed to get location');
      }

      debugPrint("Attempting to update location for user: $uid");
      await _firestore.collection('users').doc(uid).update({
        'location': {
          'latitude': locationData['latitude'],
          'longitude': locationData['longitude'],
          'address': locationData['address'],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
          "Location updated successfully now user will receive his latset locations alerts...");
    } catch (e) {
      debugPrint("Location update error: $e");
      if (e is FirebaseException) {
        debugPrint("Firebase error code: ${e.code}, message: ${e.message}");
      }
      // Don't rethrow the exception to prevent app crashes
    }
  }

  Future<bool> checkAndUpdateFCMToken(String uid) async {
    try {
      //first check user has alrady fcm token present in fcm or not
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      // If user has no FCM tokens or the array is empty, generate and add a new token
      if (userData == null || 
          userData['fcmTokens'] == null || 
          (userData['fcmTokens'] as List).isEmpty) {
        debugPrint("No FCM token found for user, generating new token");

        //here needs token to be generated as it it crucial part of the application
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await updateFCMToken(uid, fcmToken);
          return true; // Token was updated
        }
      } else {
        debugPrint("User already has FCM token, skipping generation");
      }
      return false; // No update occurred
    } catch (e) {
      debugPrint("Error checking/updating FCM token: $e");
      // Don't rethrow to prevent app crashes
      return false;
    }
  }

  Future<void> updateFCMToken(String uid, String token) async {
      try {
        debugPrint("Updating FCM token for user: $uid");
        
        // First check if the token already exists to avoid duplicates
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final userData = userDoc.data();
        
        // If user has fcmTokens array and it contains this token, don't add it again
        if (userData != null && 
            userData['fcmTokens'] != null && 
            (userData['fcmTokens'] as List).any((t) => t['token'] == token)) {
          debugPrint("Token already exists, skipping update");
          return;
        }
        
        // Add the new token with ISO string timestamp instead of serverTimestamp
        await _firestore.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayUnion([
            {
              'token': token,
              'createdAt': DateTime.now().toIso8601String(),
            }
          ]),
          'updatedAt': FieldValue.serverTimestamp(), // This is fine in update()
        });
        
        debugPrint("FCM token updated successfully");
      } catch (e) {
        debugPrint("FCM token update error: $e");
        // Don't throw to prevent app crashes
      }
    }
}
