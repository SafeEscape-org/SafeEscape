import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String alertId;
  final String type; // e.g., Flood, Earthquake
  final String description;
  final GeoPoint location;
  final DateTime timestamp;

  AlertModel({
    required this.alertId,
    required this.type,
    required this.description,
    required this.location,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'description': description,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AlertModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AlertModel(
      alertId: doc.id,
      type: data['type'],
      description: data['description'],
      location: data['location'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
