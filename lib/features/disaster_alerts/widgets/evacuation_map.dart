import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';

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
  late AnimationController _controller;
  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.currentPosition,
            zoom: 14.0,
            tilt: 0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: _currentMapType,
          trafficEnabled: _trafficEnabled,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
            _setMapStyle(controller);
          },
          markers: _createMarkers(),
          polylines: widget.polylines,
        ),
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              _buildControlButton(
                icon: Icons.layers,
                onPressed: _toggleMapType,
                tooltip: 'Change Map Type',
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.traffic,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _trafficEnabled = !_trafficEnabled);
                },
                tooltip: 'Toggle Traffic',
                isActive: _trafficEnabled,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.my_location,
                onPressed: _goToCurrentLocation,
                tooltip: 'My Location',
              ),
            ],
          ),
        ),
        if (widget.polylines.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildRouteInfoPanel(),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        color: isActive ? Colors.white : Colors.black87,
        tooltip: tooltip,
      ),
    );
  }

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
              _buildRouteDetail(Icons.timer, '15 min'),
              _buildRouteDetail(Icons.directions_car, '5.2 km'),
              _buildRouteDetail(Icons.speed, 'Fastest'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _toggleMapType() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
              ? MapType.hybrid
              : MapType.normal;
    });
  }

  void _goToCurrentLocation() {
    HapticFeedback.selectionClick();
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: widget.currentPosition,
          zoom: 15.0,
          tilt: 45.0,
          bearing: 0.0,
        ),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      widget.polylines.clear();
    });
  }
}
