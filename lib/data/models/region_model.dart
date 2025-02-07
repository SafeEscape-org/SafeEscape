import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String userId;
  final String alertType;
  final DateTime createdAt;

  SubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    required this.alertType,
    required this.createdAt,
  });

  // Convert Firestore document to SubscriptionModel
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      subscriptionId: doc.id,
      userId: data['userId'],
      alertType: data['alertType'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert SubscriptionModel to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'alertType': alertType,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
