import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

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

      String? address = await _getAddressFromCoordinates(
          position.latitude, position.longitude);

      return {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "address": address,
        "lastFetched": DateTime.now().toString(),
      };
    } catch (e) {
      debugPrint("Error fetching location: $e");
      return null;
    }
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

    return true;
  }

  static Future<String?> _getAddressFromCoordinates(double lat, double lon) async {
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
}