import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/evacuation_place.dart';
import '../../../core/constants/api_constants.dart';

class PlacesService {
  static Future<List<EvacuationPlace>> getNearbyPlaces(
    double lat,
    double lng, {
    required String type,
    int radius = 5000,
    String? pageToken,
  }) async {
    final queryParams = {
      'location': '$lat,$lng',
      'radius': '$radius',
      'type': type,
      'key': ApiConstants.googleApiKey,
    };
    
    if (pageToken != null) {
      queryParams['pagetoken'] = pageToken;
    }
    
    final url = Uri.parse(
      '${ApiConstants.nearbyPlacesBaseUrl}'
    ).replace(queryParameters: queryParams);

    try {
      // Add a small delay when using pageToken as Google API requires it
      if (pageToken != null) {
        await Future.delayed(const Duration(seconds: 2));
      }
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          final places = results
              .map((place) => EvacuationPlace.fromJson(place))
              .toList();
              
          // Return both places and next page token if available
          return places;
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        }
        throw Exception('API Error: ${data['status']}');
      }
      throw Exception('Failed to fetch nearby places: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }

  // This method returns both places and next page token
  static Future<Map<String, dynamic>> getNearbyPlacesWithToken(
    double lat,
    double lng, {
    required String type,
    int radius = 5000,
    String? pageToken,
  }) async {
    final queryParams = {
      'location': '$lat,$lng',
      'radius': '$radius',
      'type': type,
      'key': ApiConstants.googleApiKey,
    };
    
    if (pageToken != null) {
      queryParams['pagetoken'] = pageToken;
    }
    
    final url = Uri.parse(
      '${ApiConstants.nearbyPlacesBaseUrl}'
    ).replace(queryParameters: queryParams);

    try {
      // Add a small delay when using pageToken as Google API requires it
      if (pageToken != null) {
        await Future.delayed(const Duration(seconds: 2));
      }
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          final places = results
              .map((place) => EvacuationPlace.fromJson(place))
              .toList();
              
          // Return both places and next page token if available
          return {
            'places': places,
            'next_page_token': data['next_page_token'],
          };
        } else if (data['status'] == 'ZERO_RESULTS') {
          return {'places': []};
        }
        throw Exception('API Error: ${data['status']}');
      }
      throw Exception('Failed to fetch nearby places: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }

  static Future<List<LatLng>> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&alternatives=true'
      '&avoid=tolls'
      '&key=${ApiConstants.googleApiKey}'
    );

    try {
      final response = await http.get(url);
      print('API URL: $url');
      print('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List<dynamic> legs = route['legs'];
          
          List<LatLng> points = [];
          for (var leg in legs) {
            final List<dynamic> steps = leg['steps'];
            
            for (var step in steps) {
              final polyline = step['polyline']['points'];
              final polylinePoints = PolylinePoints();
              final decodedPoints = polylinePoints.decodePolyline(polyline);
              
              points.addAll(
                decodedPoints.map((point) => LatLng(point.latitude, point.longitude))
              );
            }
          }
          
          if (points.isEmpty) {
            throw Exception('No route found');
          }
          
          return points;
        }
        throw Exception('API Error: ${data['status']}');
      }
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    } catch (e) {
      print('Error fetching directions: $e');
      throw Exception('Error fetching directions: $e');
    }
  }

  // Add this method to generate markers from places
  static Set<Marker> generateMarkersFromPlaces({
    required List<EvacuationPlace> places,
    required LatLng currentPosition,
    Function(EvacuationPlace)? onMarkerTap,
  }) {
    final Set<Marker> markers = {};
    
    // Add user's current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    
    // Add markers for each place
    for (final place in places) {
      final marker = Marker(
        markerId: MarkerId(place.placeId),
        position: LatLng(place.lat, place.lng),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.vicinity,
        ),
        onTap: onMarkerTap != null ? () => onMarkerTap(place) : null,
      );
      
      markers.add(marker);
    }
    
    return markers;
  }
}