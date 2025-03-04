import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';
import 'dart:math' show cos, sqrt, asin;

class EvacuationMap extends StatefulWidget {
  final LatLng currentPosition;
  final List<EvacuationPlace> places;
  final Function(GoogleMapController) onMapCreated;
  final Set<Polyline> polylines;
  
  const EvacuationMap({
    Key? key,
    required this.currentPosition,
    required this.places,
    required this.onMapCreated,
    required this.polylines,
  }) : super(key: key);
  
  @override
  State<EvacuationMap> createState() => _EvacuationMapState();
}

class _EvacuationMapState extends State<EvacuationMap> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.currentPosition,
            zoom: 15,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
            if (_isDarkMode) {
              _setMapStyle(controller);
            }
          },
          markers: _createMarkers(),
          polylines: widget.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: _currentMapType,
          trafficEnabled: _trafficEnabled,
        ),
        if (widget.polylines.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildRouteInfoPanel(),
          ),
      ],
    );
  }
  // Add these properties at the top of the class
  String _routeDuration = '0';
  String _routeDistance = '0.0';
  double _averageSpeed = 0.0;
  bool _isDarkMode = false;
  late AnimationController _controller;
  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  // Add this method to the _EvacuationMapState class
  void _clearRoute() {
    setState(() {
      widget.polylines.clear();
      _routeDuration = '0';
      _routeDistance = '0.0';
      _averageSpeed = 0.0;
    });
  }
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
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
        }
      ]
    ''');
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
  @override
  void didUpdateWidget(EvacuationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polylines != oldWidget.polylines) {
      _updateRouteDetails();
    }
  }
  // Update the route info panel build method
  Widget _buildRouteInfoPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Icon(Icons.directions, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Route Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRouteDetail(Icons.timer, '$_routeDuration min'),
              _buildRouteDetail(Icons.directions_car, '$_routeDistance km'),
              _buildRouteDetail(Icons.speed, '${_averageSpeed.round()} km/h'),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildRouteDetail(IconData icon, String text) {
      return Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      );
    }
}
