//will add disaster alerts to Firestore and fetch alerts that match a given location.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a disaster alert to Firestore
  Future<void> addAlert(AlertModel alert) async {
    await _firestore.collection('alerts').doc(alert.alertId).set(alert.toFirestore());
  }

  /// Fetch alerts that match a given location
  Future<List<AlertModel>> getAlertsNearLocation(GeoPoint location) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('alerts')
        .where('location', isEqualTo: location)
        .get();

    return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
  }
}
