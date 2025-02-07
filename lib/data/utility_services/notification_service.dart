import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/location_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getAffectedUsers(
      double alertLat, double alertLong, String alertType) async {
    List<String> userTokens = [];

    QuerySnapshot usersSnapshot = await _firestore
        .collection('users')
        .where('subscribedAlerts', arrayContains: alertType)
        .get();

    for (var userDoc in usersSnapshot.docs) {
      GeoPoint userLocation = userDoc['location'];
      double userLat = userLocation.latitude;
      double userLong = userLocation.longitude;

      double distance =
          LocationService.calculateDistance(userLat, userLong, alertLat, alertLong);

      if (distance < 50) { // Send alerts to users within 50 km radius
        userTokens.add(userDoc['fcmToken']);
      }
    }

    return userTokens;
  }
}
