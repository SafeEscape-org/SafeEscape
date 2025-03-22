import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/side_navigation.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/alert_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/current_weather_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/disaster_declaration_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/recent_earthquakes_card.dart';
import 'package:disaster_management/services/location_service.dart';
import 'package:disaster_management/services/notification_service.dart';
import 'package:disaster_management/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:disaster_management/shared/widgets/chat_overlay.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:disaster_management/core/constants/api_constants.dart';

class CombinedHomeWeatherComponent extends StatefulWidget {
  const CombinedHomeWeatherComponent({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CombinedHomeWeatherComponentState createState() =>
      _CombinedHomeWeatherComponentState();
}

class _CombinedHomeWeatherComponentState
    extends State<CombinedHomeWeatherComponent> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isLoadingDisasters = false;
  String _locationName = "Mumbai, India";
  Map<String, dynamic>? _locationData;
  List<Map<String, dynamic>> _activeDisasters = [];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLocationData();
    
    // Register this screen as the active notification screen
    _notificationService.setActiveScreen(true);
  }

  @override
  void dispose() {
    // Unregister this screen when it's disposed
    _notificationService.setActiveScreen(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLocationData();
      // Re-register as active when app is resumed
      _notificationService.setActiveScreen(true);
    } else if (state == AppLifecycleState.paused) {
      // Unregister when app is paused
      _notificationService.setActiveScreen(false);
    }
  }

  Future<void> _fetchLocationData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = LocationService();
      final location = await LocationService.getCurrentLocation(context);
      
      if (location != null) {
        final address = await LocationService.getAddressFromCoordinates(
          location['latitude'], 
          location['longitude']
        );
        
        setState(() {
          _locationName = address ?? "Unknown Location";
          _locationData = {
            'latitude': location['latitude'],
            'longitude': location['longitude'],
            'city': address?.split(',').first ?? "Unknown",
          };
          _isLoading = false;
        });
        
        // Fetch disaster data after location is determined
        _fetchDisasterData();
      } else {
        setState(() {
          _locationName = "Mumbai, India";
          _locationData = {
            'city': "Mumbai",
            'latitude': 19.0760,
            'longitude': 72.8777,
          };
          _isLoading = false;
        });
        
        // Fetch disaster data with default location
        _fetchDisasterData();
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      setState(() {
        _locationName = "Mumbai, India";
        _locationData = {
          'city': "Mumbai",
          'latitude': 19.0760,
          'longitude': 72.8777,
        };
        _isLoading = false;
      });
      
      // Fetch disaster data with default location
      _fetchDisasterData();
    }
  }

  // Add method to fetch disaster data
  Future<void> _fetchDisasterData() async {
    if (_locationData == null) return;
    
    setState(() {
      _isLoadingDisasters = true;
    });
    
    try {
      // Get current user ID from Firebase
      String userId = "user123"; // Default fallback
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          userId = currentUser.uid;
        }
      } catch (e) {
        debugPrint('Error getting Firebase user: $e');
      }
      
      final response = await http.post(
        Uri.parse(ApiConstants.disasterAlertsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "userId": userId,
          "location": {
            "latitude": _locationData?['latitude'] ?? 19.0760,
            "longitude": _locationData?['longitude'] ?? 72.8777
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['disasters'] != null) {
          setState(() {
            _activeDisasters = List<Map<String, dynamic>>.from(data['disasters']);
            _isLoadingDisasters = false;
          });
        } else {
          setState(() {
            _activeDisasters = [];
            _isLoadingDisasters = false;
          });
        }
      } else {
        setState(() {
          _activeDisasters = [];
          _isLoadingDisasters = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching disaster data: $e');
      setState(() {
        _activeDisasters = [];
        _isLoadingDisasters = false;
      });
    }
  }






  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      locationName: _isLoading ? "Loading..." : _locationName,
      backgroundColor: AppColors.backgroundColor,
      drawer: const SideNavigation(userName: 'abc'),
      body: RefreshIndicator(
        onRefresh: _fetchLocationData,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Content
            SliverToBoxAdapter(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Weather Section
          _buildSectionTitle('Current Weather'),
          _isLoading 
            ? _buildSimpleLoading(height: 180)
            : CurrentWeatherCard(city: _locationData?['city'] ?? 'Mumbai'),
          
          const SizedBox(height: 24),
          
          // Active Alerts Section
          _buildSectionTitle('Active Alerts'),
          _isLoading || _isLoadingDisasters
            ? Column(
                children: [
                  _buildSimpleLoading(height: 120),
                  const SizedBox(height: 12),
                  _buildSimpleLoading(height: 120),
                ],
              )
            : _buildActiveAlerts(),
          
          const SizedBox(height: 24),
          
          // Recent Earthquakes Section
          _buildSectionTitle('Recent Earthquakes'),
          _isLoading 
            ? _buildSimpleLoading(height: 200)
            : const RecentEarthquakesCard(),
          
          const SizedBox(height: 24),
          
          // Disaster Declarations Section
          _buildSectionTitle('Disaster Declarations'),
          _isLoading || _isLoadingDisasters
            ? Column(
                children: [
                  _buildSimpleLoading(height: 100),
                  const SizedBox(height: 12),
                  _buildSimpleLoading(height: 100),
                  const SizedBox(height: 12),
                  _buildSimpleLoading(height: 100),
                ],
              )
            : _buildDisasterDeclarations(),
          
          // Add some padding at the bottom
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // Add method to build active alerts from API data
  Widget _buildActiveAlerts() {
    if (_activeDisasters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No active alerts for your area',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    // Filter high severity disasters for alerts
    final highSeverityDisasters = _activeDisasters
        .where((disaster) => 
            disaster['severity'] == 'high' || 
            disaster['severity'] == 'severe' ||
            disaster['severity'] == 'medium')
        .take(3)
        .toList();
    
    if (highSeverityDisasters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No high severity alerts for your area',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: highSeverityDisasters.map((disaster) {
        final Color alertColor = _getAlertColor(disaster['type']);
        final String timeAgo = _getTimeAgo(disaster['timestamp']);
        
        // Truncate description to keep card size consistent
        String description = disaster['description'] ?? '';
        if (description.length > 100) {
          description = description.substring(0, 100) + '...';
        }
        
        return AlertCard(
          title: disaster['title'],
          description: description,
          severity: _capitalizeSeverity(disaster['severity']),
          time: timeAgo,
          alertType: disaster['type'],
          color: alertColor,
        );
      }).toList(),
    );
  }
  
  // Add method to build disaster declarations from API data
  Widget _buildDisasterDeclarations() {
    if (_activeDisasters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No disaster declarations for your area',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: _activeDisasters.map((disaster) {
        final String formattedDate = _formatDate(disaster['timestamp']);
        final String disasterType = disaster['type'] ?? 'Unknown';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DisasterDeclarationCard(
            title: disaster['title'] ?? 'Unknown Disaster',
            type: _capitalizeFirstLetter(disasterType),
            location: '${disaster['location']['city'] ?? 'Unknown'}, ${disaster['location']['state'] ?? ''}',
            date: formattedDate,
            status: disaster['active'] == true ? 'Active' : 'Closed',
          ),
        );
      }).toList(),
    );
  }
  
  // Helper method to get alert color based on type
  Color _getAlertColor(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Colors.blue;
      case 'fire':
        return Colors.orange;
      case 'earthquake':
        return Colors.red;
      case 'storm':
        return Colors.purple;
      case 'pollution':
        return Colors.brown;
      case 'hurricane':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }
  
  // Helper method to format timestamp to relative time
  String _getTimeAgo(String timestamp) {
    final DateTime now = DateTime.now();
    final DateTime date = DateTime.parse(timestamp);
    final Duration difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Helper method to format date
  String _formatDate(String timestamp) {
    final DateTime date = DateTime.parse(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Helper method to capitalize severity
  String _capitalizeSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Moderate';
      case 'low':
        return 'Low';
      case 'severe':
        return 'Severe';
      default:
        return _capitalizeFirstLetter(severity);
    }
  }
  
  // Add this new shimmer loading widget
  // Replace the shimmer loading widget with a simpler loading indicator
  Widget _buildSimpleLoading({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
