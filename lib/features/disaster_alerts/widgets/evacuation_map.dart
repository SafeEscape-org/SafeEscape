import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';
import 'dart:math' show cos, sqrt, asin;
import '../constants/colors.dart';
import 'dart:async';

class EvacuationMap extends StatefulWidget {
  final LatLng currentPosition;
  final List<EvacuationPlace> places;
  final Function(GoogleMapController) onMapCreated;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final bool isExpanded; // Add this parameter
  
  const EvacuationMap({
    Key? key,
    required this.currentPosition,
    required this.places,
    required this.polylines,
    this.markers = const {},
    required this.onMapCreated,
    this.isExpanded = false, // Default to false
  }) : super(key: key);
  
  @override
  State<EvacuationMap> createState() => _EvacuationMapState();
}

class _EvacuationMapState extends State<EvacuationMap> with SingleTickerProviderStateMixin {
  // Properties
  String _routeDuration = '0';
  String _routeDistance = '0.0';
  double _averageSpeed = 0.0;
  bool _isDarkMode = false;
  bool _isMapControlsVisible = false;
  bool _isAnimatingRoute = false;
  late AnimationController _controller;
  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  Timer? _routeAnimationTimer;
  List<LatLng> _animatedPoints = [];
  Set<Polyline> _animatedPolylines = {};
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Start route animation if polylines exist
    if (widget.polylines.isNotEmpty) {
      _startRouteAnimation();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _routeAnimationTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(EvacuationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polylines != oldWidget.polylines) {
      _updateRouteDetails();
      if (widget.polylines.isNotEmpty) {
        _startRouteAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: widget.isExpanded 
              ? MediaQuery.of(context).size.height 
              : MediaQuery.of(context).size.height * 0.4,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentPosition,
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              
              // Add a slight delay to ensure the map is properly initialized
              Future.delayed(const Duration(milliseconds: 100), () {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(widget.currentPosition, 15),
                );
                widget.onMapCreated(controller);
                if (_isDarkMode) {
                  _setMapStyle(controller);
                }
              });
            },
            markers: widget.markers.isEmpty ? _createMarkers() : widget.markers,
            polylines: _isAnimatingRoute ? _animatedPolylines : widget.polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll add our own button
            mapType: _currentMapType,
            trafficEnabled: _trafficEnabled,
            compassEnabled: true,
            zoomControlsEnabled: false, // We'll add our own controls
          ),
        ),
        
        // Map controls - adjust position based on expanded state
        Positioned(
          right: 16,
          top: widget.isExpanded ? MediaQuery.of(context).padding.top + 16 : 16,
          child: _buildMapControls(),
        ),
        
        // Zoom controls - adjust position based on expanded state
        Positioned(
          right: 16,
          bottom: widget.polylines.isNotEmpty 
                ? (widget.isExpanded ? 120 : 100) 
                : 16,
          child: _buildZoomControls(),
        ),
        
        // Route info panel - modify this part
        if (widget.polylines.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 100, // Set a fixed height for the panel
              child: _buildFloatingRouteInfoPanel(),
            ),
          ),
      ],
    );
  }

  // Replace your existing _buildRouteInfoPanel with this floating version
  Widget _buildFloatingRouteInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Semi-transparent background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Route icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EvacuationColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions,
              color: EvacuationColors.primaryColor,
              size: 20,
            ),
          ),
          
          // Route details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Route to Destination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: EvacuationColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_routeDistance km • $_routeDuration min',
                    style: TextStyle(
                      fontSize: 12,
                      color: EvacuationColors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation button
          ElevatedButton.icon(
            onPressed: () {
              // Start navigation logic
            },
            icon: const Icon(Icons.navigation, size: 16),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvacuationColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map type button
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              _showMapTypeSelector();
            },
          ),
          
          // Traffic toggle
          IconButton(
            icon: Icon(
              Icons.traffic_outlined,
              color: _trafficEnabled 
                  ? EvacuationColors.primaryColor 
                  : Colors.grey[600],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _trafficEnabled = !_trafficEnabled;
              });
            },
          ),
          
          // Dark mode toggle
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: _isDarkMode 
                  ? EvacuationColors.primaryColor 
                  : Colors.grey[600],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isDarkMode = !_isDarkMode;
                _setMapStyle(_mapController);
              });
            },
          ),
          
          // My location button
          IconButton(
            icon: const Icon(Icons.my_location),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              _mapController.animateCamera(
                CameraUpdate.newLatLng(widget.currentPosition),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zoom in
          IconButton(
            icon: const Icon(Icons.add),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              _mapController.animateCamera(CameraUpdate.zoomIn());
            },
          ),
          
          // Zoom out
          IconButton(
            icon: const Icon(Icons.remove),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              _mapController.animateCamera(CameraUpdate.zoomOut());
            },
          ),
        ],
      ),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Select Map Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMapTypeOption(
              'Standard', 
              Icons.map_outlined, 
              MapType.normal,
            ),
            _buildMapTypeOption(
              'Satellite', 
              Icons.satellite_outlined, 
              MapType.satellite,
            ),
            _buildMapTypeOption(
              'Terrain', 
              Icons.terrain_outlined, 
              MapType.terrain,
            ),
            _buildMapTypeOption(
              'Hybrid', 
              Icons.layers_outlined, 
              MapType.hybrid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, IconData icon, MapType mapType) {
    final isSelected = _currentMapType == mapType;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? EvacuationColors.primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? EvacuationColors.primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check, color: EvacuationColors.primaryColor) 
          : null,
      onTap: () {
        setState(() {
          _currentMapType = mapType;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    if (_isDarkMode) {
      await controller.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#242f3e"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#746855"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#242f3e"}]
          },
          {
            "featureType": "administrative.locality",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#d59563"}]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#d59563"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry",
            "stylers": [{"color": "#263c3f"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#6b9a76"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [{"color": "#38414e"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#212a37"}]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#9ca5b3"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [{"color": "#746855"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#1f2835"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#f3d19c"}]
          },
          {
            "featureType": "transit",
            "elementType": "geometry",
            "stylers": [{"color": "#2f3948"}]
          },
          {
            "featureType": "transit.station",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#d59563"}]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [{"color": "#17263c"}]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#515c6d"}]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#17263c"}]
          }
        ]
      ''');
    } else {
      await controller.setMapStyle(null); // Reset to default style
    }
  }

  Set<Marker> _createMarkers() {
    final Set<Marker> markers = {};
    
    for (var place in widget.places) {
      markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.lat, place.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.vicinity,
          ),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    return markers;
  }

  void _updateRouteDetails() {
    if (widget.polylines.isEmpty) return;
    
    double totalDistance = 0;
    final points = widget.polylines.first.points;
    
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    
    final durationInMinutes = (totalDistance * 1.5).round();
    
    setState(() {
      _routeDuration = durationInMinutes.toString();
      _routeDistance = totalDistance.toStringAsFixed(1);
      _averageSpeed = totalDistance / (durationInMinutes / 60);
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((end.latitude - start.latitude) * p)/2 + 
            c(start.latitude * p) * c(end.latitude * p) * 
            (1 - c((end.longitude - start.longitude) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _clearRoute() {
    setState(() {
      widget.polylines.clear();
      _animatedPolylines.clear();
      _animatedPoints.clear();
      _routeDuration = '0';
      _routeDistance = '0.0';
      _averageSpeed = 0.0;
      _isAnimatingRoute = false;
    });
    _routeAnimationTimer?.cancel();
  }

  void _startRouteAnimation() {
    // Cancel any existing animation
    _routeAnimationTimer?.cancel();
    
    if (widget.polylines.isEmpty) return;
    
    setState(() {
      _isAnimatingRoute = true;
      _animatedPoints = [];
      _animatedPolylines = {};
    });
    
    final allPoints = widget.polylines.first.points;
    final totalPoints = allPoints.length;
    int currentPointIndex = 0;
    
    // Create a timer that adds points to the animated polyline
    _routeAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentPointIndex >= totalPoints) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Add the next point to our animated points list
        _animatedPoints.add(allPoints[currentPointIndex]);
        
        // Create a new polyline with the current points
        _animatedPolylines = {
          Polyline(
            polylineId: const PolylineId('animated_route'),
            points: _animatedPoints,
            color: EvacuationColors.primaryColor,
            width: 5,
            patterns: [
              PatternItem.dash(20),
              PatternItem.gap(5),
            ],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
      
      currentPointIndex++;
      
      // If we've added all points, stop the animation
      if (currentPointIndex >= totalPoints) {
        setState(() {
          _isAnimatingRoute = false;
        });
        timer.cancel();
      }
    });
  }

  Widget _buildRouteInfoPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for dragging
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EvacuationColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions,
                  color: EvacuationColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Route Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: EvacuationColors.textColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _clearRoute();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[400],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Route details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EvacuationColors.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRouteDetailCard(
                  Icons.timer,
                  '$_routeDuration min',
                  'Duration',
                ),
                _buildRouteDetailCard(
                  Icons.directions_car,
                  '$_routeDistance km',
                  'Distance',
                ),
                _buildRouteDetailCard(
                  Icons.speed,
                  '${_averageSpeed.round()} km/h',
                  'Avg. Speed',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation button
          ElevatedButton.icon(
            onPressed: () {
              // Start navigation logic here
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation started'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Start Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvacuationColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: EvacuationColors.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: EvacuationColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: EvacuationColors.subtitleColor,
          ),
        ),
      ],
    );
  }
}