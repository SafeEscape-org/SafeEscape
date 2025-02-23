import 'package:disaster_management/features/disaster_alerts/models/evacuation_place.dart';
import 'package:disaster_management/features/disaster_alerts/services/places_service.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:disaster_management/services/location_service.dart'; // Import the service file
import 'package:disaster_management/features/disaster_alerts/widgets/evacuation_map.dart';

class EvacuationScreen extends StatefulWidget {
  const EvacuationScreen({super.key});

  @override
  _EvacuationScreenState createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen> {
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  bool _locationPermissionDenied = false;
  List<EvacuationPlace> _places = [];
  bool _isLoading = false;
  Set<Polyline> _polylines = {}; // Add this line
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData != null) {
        final position = LatLng(
          locationData["latitude"] as double,
          locationData["longitude"] as double,
        );
        setState(() => _currentPosition = position);
        await _fetchNearbyPlaces();
      } else {
        setState(() => _locationPermissionDenied = true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) return;

    try {
      final places = await PlacesService.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() => _places = places);
    } catch (e) {
      // Handle error appropriately
      print('Error fetching places: $e');
    }
  }

  Future<void> _showRouteToPlace(EvacuationPlace place) async {
    try {
      final polylinePoints = await PlacesService.getDirections(
        origin: _currentPosition!,
        destination: LatLng(place.lat, place.lng),
      );

      print("polylines ${polylinePoints}");

      if (polylinePoints.isNotEmpty) {
        final String polylineId = 'route_${place.placeId}';

        // Create new route
        final Polyline routePolyline = Polyline(
          polylineId: PolylineId(polylineId),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        );

        // Update map camera to show entire route
        LatLngBounds bounds = _getBoundsForRoute(polylinePoints);
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );

        setState(() {
          _polylines.clear(); // Clear previous routes
          _polylines.add(routePolyline); // Add new route
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to fetch route. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  LatLngBounds _getBoundsForRoute(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                const HeaderComponent(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchNearbyPlaces,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Container(
                            height: screenHeight * 0.35, // 35% of screen height
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  spreadRadius: 2,
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: _locationPermissionDenied
                                ? _buildPermissionDeniedMessage()
                                : _currentPosition == null
                                    ? _buildLoadingIndicator()
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: EvacuationMap(
                                          currentPosition: _currentPosition!,
                                          places: _places,
                                          polylines: _polylines, // Add this line
                                          onMapCreated: (controller) {
                                            mapController = controller;
                                          },
                                        ),
                                      ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            height: screenHeight *
                                0.5, // Fixed height for list section
                            child: _places.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_searching,
                                          size: 48,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No nearby places found',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _places.length,
                                    itemBuilder: (context, index) =>
                                        _buildRouteCard(_places[index]),
                                  ),
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Update _buildRouteCard to use EvacuationPlace
  Widget _buildRouteCard(EvacuationPlace place) {
    return GestureDetector(
        onTap: () => _showRouteToPlace(place),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF404040),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions,
                color: Color(0xFF00FF00),
                size: 24,
              ),
            ),
            title: Text(
              place.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (place.rating != null)
                      _buildStatusChip(
                        icon: Icons.star,
                        text: place.rating!.toString(),
                        color: Colors.amber,
                      ),
                    _buildStatusChip(
                      icon: Icons.location_on,
                      text: place.vicinity,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildStatusChip(
      {required IconData icon, required String text, required Color color}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Display loading indicator while fetching location
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  /// Display message if location permission is denied
  Widget _buildPermissionDeniedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Location access is denied.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => LocationService.getCurrentLocation(context),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
