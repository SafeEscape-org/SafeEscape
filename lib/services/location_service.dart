import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:disaster_management/core/constants/api_constants.dart';

class LocationService {
  static const double earthRadiusKm = 6371;

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static Future<Map<String, dynamic>?> getCurrentLocation(BuildContext context) async {
    if (!await _isLocationServiceEnabled(context)) return null;
    if (!await _requestLocationPermission(context)) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String? address = await getAddressFromCoordinates(
          position.latitude, position.longitude);
          
      // Get detailed address components
      Map<String, String?> addressComponents = await _parseAddressComponents(
          position.latitude, position.longitude);

      return {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "address": address,
        "city": addressComponents["city"],
        "state": addressComponents["state"],
        "country": addressComponents["country"],
        "lastFetched": DateTime.now().toString(),
      };
    } catch (e) {
      debugPrint("Error fetching location: $e");
      return null;
    }
  }
  
  // Helper method to parse address components
  static Future<Map<String, String?>> _parseAddressComponents(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          "city": place.locality ?? place.subAdministrativeArea,
          "state": place.administrativeArea,
          "country": place.country,
        };
      }
      return {"city": null, "state": null, "country": null};
    } catch (e) {
      debugPrint("Error parsing address components: $e");
      return {"city": null, "state": null, "country": null};
    }
  }

  // New method to predict disasters based on location
  static Future<Map<String, dynamic>?> predictDisasterForLocation(Map<String, dynamic> locationData) async {
    try {
      final http.Client client = http.Client();
      final response = await client.post(
        Uri.parse(ApiConstants.disasterPredictionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "location": {
            "city": locationData["city"] ?? "Unknown",
            "state": locationData["state"] ?? "Unknown",
            "country": locationData["country"] ?? "Unknown",
            "coordinates": {
              "latitude": locationData["latitude"],
              "longitude": locationData["longitude"]
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Error predicting disaster: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception predicting disaster: $e");
      return null;
    }
  }

  // Changed from private to public method
  static Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      return placemarks.isNotEmpty
          ? "${placemarks[0].locality}, ${placemarks[0].country}"
          : "Unknown Location";
    } catch (e) {
      debugPrint("Error getting address: $e");
      return "Unknown Location";
    }
  }

  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Service Disabled"),
        content: const Text("Please enable location services to continue."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDeniedForeverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Denied Forever"),
        content: const Text(
            "Location permission is permanently denied. Please enable it from app settings."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  static Future<bool> _isLocationServiceEnabled(BuildContext context) async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog(context);
        return false;
      }
      return true;
    }

    static Future<bool> _requestLocationPermission(BuildContext context) async {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
  
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog(context);
        return false;
      }
  
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    }
}