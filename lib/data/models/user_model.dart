import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final GeoPoint location;
  final String fcmToken;
  final List<String> subscribedAlerts;
  final Timestamp? createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.location,
    required this.fcmToken,
    this.subscribedAlerts = const [],
    this.createdAt,
  });

  /// ✅ Converts UserModel to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'location': location,
      'fcmToken': fcmToken,
      'subscribedAlerts': subscribedAlerts,
      'createdAt': FieldValue.serverTimestamp(), // Firestore manages timestamp
    };
  }

  /// ✅ Converts Firestore document into UserModel
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      userId: doc.id,
      name: data['name'],
      email: data['email'],
      location: data['location'],
      fcmToken: data['fcmToken'],
      subscribedAlerts: List<String>.from(data['subscribedAlerts'] ?? []),
      createdAt: data['createdAt'],
    );
  }
}
