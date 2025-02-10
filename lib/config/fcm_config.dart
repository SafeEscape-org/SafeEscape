import 'package:firebase_messaging/firebase_messaging.dart';
// Import for kIsWeb


class FCMConfig {
  static FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initializeFCM() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      // Only request if not already authorized
      try {
        settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,  // For iOS
          badge: true,          // For iOS
          carPlay: false,       // For iOS
          criticalAlert: false, // For iOS
          provisional: false,   // For iOS
          sound: true,
        );
      } catch (e) {
        // Handle errors, like the user rejecting permissions
        print("Error requesting notification permissions: $e");
        // You might want to show a dialog to the user explaining why permissions are needed.
        return; // Stop further initialization if permissions are denied
      }
    }


    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the token only if permissions are granted.
      try {
        String? token = await _firebaseMessaging.getToken();
        print("FCM Token: $token"); // Store this token on your server!
      } catch (e) {
        print("Error getting FCM token: $e");
      }
    } else {
      print("Notification permissions not granted.");
      // Consider disabling notification-related features or showing an informational message to the user
    }
  }



  static FirebaseMessaging get firebaseMessaging => _firebaseMessaging;
}
