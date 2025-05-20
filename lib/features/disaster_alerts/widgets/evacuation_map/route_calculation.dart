import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class RouteCalculation {
  static double calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((end.latitude - start.latitude) * p)/2 + 
            c(start.latitude * p) * c(end.latitude * p) * 
            (1 - c((end.longitude - start.longitude) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static Map<String, String> calculateRouteDetails(List<LatLng> points) {
    if (points.isEmpty) {
      return {'distance': '0.0', 'duration': '0'};
    }
    
    double totalDistance = 0;
    
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i], points[i + 1]);
    }
    
    final durationInMinutes = (totalDistance * 1.5).round();
    
    return {
      'distance': totalDistance.toStringAsFixed(1),
      'duration': durationInMinutes.toString(),
    };
  }
}