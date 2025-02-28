import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final GeoPoint location;
  final List<String> emergencyContacts;
  final List<Map<String, String>> fcmTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.emergencyContacts,
    required this.fcmTokens,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': {
        'type': 'Point',
        'coordinates': [location.latitude, location.longitude],
      },
      'emergencyContacts': emergencyContacts,
      'fcmTokens': fcmTokens,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}