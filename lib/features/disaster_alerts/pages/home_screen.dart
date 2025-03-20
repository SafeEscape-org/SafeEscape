import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/side_navigation.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/alert_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/current_weather_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/disaster_declaration_card.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/recent_earthquakes_card.dart';
import 'package:disaster_management/services/location_service.dart';
import 'package:disaster_management/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';

class CombinedHomeWeatherComponent extends StatefulWidget {
  const CombinedHomeWeatherComponent({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CombinedHomeWeatherComponentState createState() =>
      _CombinedHomeWeatherComponentState();
}

class _CombinedHomeWeatherComponentState
    extends State<CombinedHomeWeatherComponent> with WidgetsBindingObserver {
  bool _isLoading = false;  // Changed from true to false
  String _locationName = "Mumbai, India";  // Changed from "Loading..." to default location
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLocationData();
  }

  Future<void> _fetchLocationData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = LocationService();
      final location = await LocationService.getCurrentLocation(context);
      
      if (location != null) {
        final address = await LocationService.getAddressFromCoordinates(  // Removed underscore
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
      } else {
        setState(() {
          _locationName = "Mumbai, India";
          _locationData = {
            'city': "Mumbai",
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      setState(() {
        _locationName = "Mumbai, India";
        _locationData = {
          'city': "Mumbai",
        };
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLocationData();
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
            ? _buildShimmerLoading(height: 180)
            : CurrentWeatherCard(city: _locationData?['city'] ?? 'Mumbai'),
          
          const SizedBox(height: 24),
          
          // Active Alerts Section
          _buildSectionTitle('Active Alerts'),
          _isLoading 
            ? Column(
                children: [
                  _buildShimmerLoading(height: 120),
                  const SizedBox(height: 12),
                  _buildShimmerLoading(height: 120),
                ],
              )
            : Column(
                children: const [
                  AlertCard(
                    title: 'Flood Warning',
                    description: 'Flash flood warning in effect until 8:00 PM',
                    severity: 'Severe',
                    time: '2 hours ago',
                    alertType: 'flood',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  AlertCard(
                    title: 'Heat Advisory',
                    description: 'Excessive heat warning until tomorrow evening',
                    severity: 'Moderate',
                    time: '5 hours ago',
                    alertType: 'fire',
                    color: Colors.orange,
                  ),
                ],
              ),
          const SizedBox(height: 24),
          
          // Recent Earthquakes Section
          _buildSectionTitle('Recent Earthquakes'),
          _isLoading 
            ? _buildShimmerLoading(height: 200)
            : const RecentEarthquakesCard(),
          
          const SizedBox(height: 24),
          
          // Disaster Declarations Section
          _buildSectionTitle('Disaster Declarations'),
          _isLoading 
            ? Column(
                children: [
                  _buildShimmerLoading(height: 100),
                  const SizedBox(height: 12),
                  _buildShimmerLoading(height: 100),
                  const SizedBox(height: 12),
                  _buildShimmerLoading(height: 100),
                ],
              )
            : Column(
                children: const [
                  DisasterDeclarationCard(
                    title: 'Severe Storms and Flooding',
                    type: 'Flood',
                    location: 'Los Angeles County, CA',
                    date: '2023-05-15',
                    status: 'Active',
                  ),
                  SizedBox(height: 12),
                  DisasterDeclarationCard(
                    title: 'Hurricane Ian',
                    type: 'Hurricane',
                    location: 'Miami-Dade County, FL',
                    date: '2023-04-22',
                    status: 'Active',
                  ),
                  SizedBox(height: 12),
                  DisasterDeclarationCard(
                    title: 'Wildfire',
                    type: 'Fire',
                    location: 'San Diego County, CA',
                    date: '2023-03-10',
                    status: 'Closed',
                  ),
                  AlertCard(
                    title: 'Earthquake Alert',
                    description: 'Magnitude 4.2 earthquake detected nearby',
                    severity: 'High',
                    time: '10 minutes ago',
                    alertType: 'earthquake',
                    color: Colors.red,
                  ),
                  SizedBox(height: 12),
                  AlertCard(
                    title: 'Storm Warning',
                    description: 'Severe thunderstorm approaching the area',
                    severity: 'Severe',
                    time: '1 hour ago',
                    alertType: 'storm',
                    color: Colors.purple,
                  ),
                ],
              ),
          const SizedBox(height: 24),
          
          // Add some padding at the bottom
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // Add this new shimmer loading widget
  Widget _buildShimmerLoading({required double height}) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: height,
              color: Colors.blue[50],
            ),
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.blue[100]!,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcATop,
                child: Container(
                  width: double.infinity,
                  height: height,
                  color: Colors.blue[50],
                ),
              ),
            ),
          ],
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
