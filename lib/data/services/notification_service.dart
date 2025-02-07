import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendNotification(String userId, String message) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    String? fcmToken = userDoc.get('fcmToken');

    if (fcmToken != null) {
      await _firebaseMessaging.sendMessage(
        to: fcmToken,
        data: {'message': message},
      );
    }
  }
}
