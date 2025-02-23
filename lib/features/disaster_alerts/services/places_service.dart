import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/evacuation_place.dart';
import '../../../core/constants/api_constants.dart';

class PlacesService {
  static Future<List<EvacuationPlace>> getNearbyPlaces(double lat, double lng) async {
    final url = Uri.parse(
      '${ApiConstants.nearbyPlacesBaseUrl}?'
      'location=$lat,$lng'
      '&radius=${ApiConstants.searchRadius}'
      '&type=hospital'
      '&key=${ApiConstants.googleApiKey}'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results
            .map((place) => EvacuationPlace.fromJson(place))
            .toList();
      }
      throw Exception('Failed to fetch nearby places');
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }
  static Future<List<LatLng>> getDirections({
      required LatLng origin,
      required LatLng destination,
    }) async {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=${ApiConstants.googleApiKey}';
  
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Decode polyline points
          final points = data['routes'][0]['overview_polyline']['points'];
          return PolylinePoints()
              .decodePolyline(points)
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }
      }
      throw Exception('Failed to fetch directions');
    }
}