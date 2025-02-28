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
  }) async {
    try {
      print("inside register user method call");
      // Get location first
      final locationData = await LocationService.getCurrentLocation(context);
      print("got location data: " + locationData.toString());
      if (locationData == null) {
        throw Exception('Location is required for registration');
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get FCM token for notifications
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Create user document with additional info
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'location': {
          'type': 'Point',
          'coordinates': [locationData['latitude'], locationData['longitude']],
          'address': locationData['address'],
        },
        'emergencyContacts': emergencyContacts,
        'fcmTokens': [{
          'token': fcmToken,
          'createdAt': DateTime.now().toIso8601String(), // Use ISO string instead of serverTimestamp
        }],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('User document created successfully');

      return userCredential;
    } catch (e) {
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
      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData == null) {
        throw Exception('Failed to get location');
      }

      await _firestore.collection('users').doc(uid).update({
        'location': {
          'type': 'Point',
          'coordinates': [locationData['latitude'], locationData['longitude']],
          'address': locationData['address'],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<void> updateFCMToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([
          {
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }
}
