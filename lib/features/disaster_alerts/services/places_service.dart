import 'dart:convert';
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
}