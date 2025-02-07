// allows users to suscribe specific disaster
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Subscribe a user to an alert type
  Future<void> subscribeUserToAlert(String userId, String alertType) async {
    await _firestore.collection('users').doc(userId).update({
      'subscribedAlerts': FieldValue.arrayUnion([alertType])
    });
  }

  /// Unsubscribe a user from an alert type
  Future<void> unsubscribeUserFromAlert(String userId, String alertType) async {
    await _firestore.collection('users').doc(userId).update({
      'subscribedAlerts': FieldValue.arrayRemove([alertType])
    });
  }

  /// Get a user's subscribed alerts
  Future<List<String>> getUserSubscriptions(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? List<String>.from(doc.data()?['subscribedAlerts'] ?? []) : [];
  }
}
