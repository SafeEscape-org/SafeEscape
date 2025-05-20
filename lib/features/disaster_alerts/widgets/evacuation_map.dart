import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';
import 'dart:math' show cos, sqrt, asin;
import '../constants/colors.dart';
import 'dart:async';
// Import components from evacuation_map directory
import 'evacuation_map/map_style_utils.dart';
import 'evacuation_map/map_controls.dart';
import 'evacuation_map/route_info_panel.dart';
import 'evacuation_map/route_animation.dart';
import 'evacuation_map/route_calculation.dart';

class EvacuationMap extends StatefulWidget {
  final LatLng currentPosition;
  final List<EvacuationPlace> places;
  final Function(GoogleMapController) onMapCreated;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final bool isExpanded;
  final Function(bool)? onNavigationStarted; // Add this callback

  const EvacuationMap({
    Key? key,
    required this.currentPosition,
    required this.places,
    required this.polylines,
    this.markers = const {},
    required this.onMapCreated,
    this.isExpanded = false,
    this.onNavigationStarted, // Add this parameter
  }) : super(key: key);

  @override
  State<EvacuationMap> createState() => _EvacuationMapState();
}

class _EvacuationMapState extends State<EvacuationMap>
    with SingleTickerProviderStateMixin {
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
  late RouteAnimator _routeAnimator;
  Set<Marker> _localMarkers = {}; // Add this line to store local markers

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _routeAnimator = RouteAnimator();
    
    // Initialize markers on startup
    _localMarkers = _createMarkers();

    // Start route animation if polylines exist
    if (widget.polylines.isNotEmpty) {
      _startRouteAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _routeAnimator.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EvacuationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.polylines != oldWidget.polylines) {
      _updateRouteDetails();
      if (widget.polylines.isNotEmpty) {
        _routeAnimator.startAnimation(
          widget.polylines,
          (polylines) {
            setState(() {
              // This updates the UI when animation progresses
              _isAnimatingRoute = true;
            });
          },
          () {
            setState(() {
              _isAnimatingRoute = false;
            });
          }
        );
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
                  MapStyleUtils.setMapStyle(controller, _isDarkMode);
                }
              });
            },
            markers: widget.markers.isEmpty ? _localMarkers : widget.markers,
            polylines: _isAnimatingRoute
                ? _routeAnimator.animatedPolylines
                : widget.polylines,
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
                mainAxisSize: MainAxisSize.max,
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
              if (widget.onNavigationStarted != null) {
                widget.onNavigationStarted!(true); // Request map expansion
              }
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
    return MapControls(
      isDarkMode: _isDarkMode,
      trafficEnabled: _trafficEnabled,
      onMapTypePressed: () {
        setState(() {
          _currentMapType = _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.normal;
        });
      },
      onTrafficToggled: () {
        setState(() {
          _trafficEnabled = !_trafficEnabled;
        });
      },
      onDarkModeToggled: () {
        setState(() {
          _isDarkMode = !_isDarkMode;
          MapStyleUtils.setMapStyle(_mapController,_isDarkMode);
        });
      },
      onMyLocationPressed: () {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(widget.currentPosition, 15),
        );
      },
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
      totalDistance +=
          RouteCalculation.calculateDistance(points[i], points[i + 1]);
    }

    final durationInMinutes = (totalDistance * 1.5).round();

    setState(() {
      _routeDuration = durationInMinutes.toString();
      _routeDistance = totalDistance.toStringAsFixed(1);
      _averageSpeed = totalDistance / (durationInMinutes / 60);
    });
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

  void _startRouteAnimation() {
    if (widget.polylines.isEmpty) return;
    
    setState(() {
      _isAnimatingRoute = true;
    });
    
    _routeAnimator.startAnimation(
      widget.polylines,
      (polylines) {
        setState(() {
          // This updates the UI when animation progresses
        });
      },
      () {
        setState(() {
          _isAnimatingRoute = false;
        });
      }
    );
  }
}
