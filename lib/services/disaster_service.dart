import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:disaster_management/core/constants/api_constants.dart';

class DisasterService {
  // Singleton pattern
  static final DisasterService _instance = DisasterService._internal();
  
  factory DisasterService() {
    return _instance;
  }
  
  DisasterService._internal();
  
  // Cache for disaster data
  Map<String, dynamic> _cache = {};
  DateTime? _lastFetchTime;
  
  // Method to get user ID
  Future<String> getUserId() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      return currentUser?.uid ?? "user123";
    } catch (e) {
      debugPrint('Error getting Firebase user: $e');
      return "user123"; // Default fallback
    }
  }
  
  // Parse JSON in a separate isolate to avoid blocking UI thread
  static Future<List<Map<String, dynamic>>> _parseDisastersJson(String responseBody) async {
    final parsed = await compute(_parseJson, responseBody);
    if (parsed['success'] == true && parsed['disasters'] != null) {
      return List<Map<String, dynamic>>.from(parsed['disasters']);
    }
    return [];
  }
  
  // Helper method for compute
  static Map<String, dynamic> _parseJson(String responseBody) {
    return json.decode(responseBody);
  }
  
  // Main method to fetch disaster data
  Future<List<Map<String, dynamic>>> fetchDisasterData(Map<String, dynamic>? locationData) async {
    if (locationData == null) return [];
    
    // Check cache if it's less than 5 minutes old
    final String cacheKey = "${locationData['latitude']}-${locationData['longitude']}";
    final bool isCacheValid = _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5 &&
        _cache.containsKey(cacheKey);
    
    if (isCacheValid) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }
    
    try {
      final String userId = await getUserId();
      
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        "userId": userId,
        "location": {
          "latitude": locationData['latitude'] ?? 19.0760,
          "longitude": locationData['longitude'] ?? 72.8777
        }
      };
      
      // Make API request
      final response = await http.post(
        Uri.parse(ApiConstants.disasterAlertsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        // Parse response in a separate isolate
        final disasters = await _parseDisastersJson(response.body);
        
        // Update cache
        _cache[cacheKey] = disasters;
        _lastFetchTime = DateTime.now();
        
        return disasters;
      } else {
        debugPrint('Error response: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching disaster data: $e');
      return [];
    }
  }
}