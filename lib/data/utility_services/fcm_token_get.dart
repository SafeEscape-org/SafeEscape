import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update user's FCM token
  Future<void> updateFCMToken(String userId, String newToken) async {
    await _firestore.collection('users').doc(userId).update({'fcmToken': newToken});
  }

  /// Get a user's FCM token
  Future<String?> getFCMToken(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists && doc.data() != null ? doc.data()!['fcmToken'] : null;
  }
}
