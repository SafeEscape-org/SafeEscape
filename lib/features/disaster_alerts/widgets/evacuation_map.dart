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
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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
        _routeAnimator.startAnimation(widget.polylines, (polylines) {
            setState(() {
              // This updates the UI when animation progresses
              _isAnimatingRoute = true;
            });
        }, () {
            setState(() {
              _isAnimatingRoute = false;
            });
        });
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
    // Get screen width to calculate adaptive spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Calculate adaptive sizes
    final double iconSize = isSmallScreen ? 18 : 20;
    final double fontSize = isSmallScreen ? 12 : 14;
    final double buttonFontSize = isSmallScreen ? 12 : 14;
    final double padding = isSmallScreen ? 8 : 12;
    final double spacing = isSmallScreen ? 6 : 12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.95), // More opaque for better readability
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row with route info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Route icon
          Container(
                padding: EdgeInsets.all(padding * 0.75),
            decoration: BoxDecoration(
              color: EvacuationColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions,
              color: EvacuationColors.primaryColor,
                  size: iconSize,
            ),
          ),

          // Route details
          Expanded(
            child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Route to Destination',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                      color: EvacuationColors.textColor,
                    ),
                  ),
                      SizedBox(height: spacing / 3),
                  Text(
                    '$_routeDistance km • $_routeDuration min',
                        style: GoogleFonts.inter(
                          fontSize: fontSize - 2,
                      color: EvacuationColors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),

          // Spacing between rows
          SizedBox(height: spacing * 0.75),

          // Button row
          Container(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                _showAIRoutingDialog();
                // Start navigation logic after AI "processing"
                Future.delayed(const Duration(milliseconds: 2500), () {
              if (widget.onNavigationStarted != null) {
                widget.onNavigationStarted!(true); // Request map expansion
              }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: padding * 0.75, horizontal: padding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EvacuationColors.primaryColor,
                      EvacuationColors.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: EvacuationColors.primaryColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated navigation icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 0.1 * math.sin(value * 10),
                          child: Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: spacing / 2),
                    // Button text
                    Text(
                      'AI-Optimized Route',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: buttonFontSize,
                      ),
                    ),
                  ],
                ),
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
          MapStyleUtils.setMapStyle(_mapController, _isDarkMode);
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
    
    _routeAnimator.startAnimation(widget.polylines, (polylines) {
        setState(() {
          // This updates the UI when animation progresses
        });
    }, () {
        setState(() {
          _isAnimatingRoute = false;
      });
    });
  }

  // Add this method to show the AI routing dialog
  void _showAIRoutingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI processing animation
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating circle
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 4.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * math.pi,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EvacuationColors.primaryColor
                                    .withOpacity(0.3),
                                width: 3,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                              gradient: SweepGradient(
                                colors: [
                                  EvacuationColors.primaryColor
                                      .withOpacity(0.0),
                                  EvacuationColors.primaryColor,
                                ],
                                stops: const [0.7, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner pulsing circle
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: EvacuationColors.primaryColor
                                  .withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.route_rounded,
                              color: EvacuationColors.primaryColor,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Processing text
              Text(
                'AI Optimizing Route',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: EvacuationColors.textColor,
                ),
              ),
              const SizedBox(height: 12),
              // Processing message
              Text(
                'Analyzing traffic, weather conditions, and emergency factors to find the safest and fastest evacuation route.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: EvacuationColors.subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              // Processing indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProcessingIndicator('Traffic', Colors.orange),
                  const SizedBox(width: 12),
                  _buildProcessingIndicator('Weather', Colors.blue),
                  const SizedBox(width: 12),
                  _buildProcessingIndicator('Safety', Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Close dialog after 2 seconds
    Future.delayed(const Duration(milliseconds: 2300), () {
      Navigator.of(context).pop();
    });
  }

  // Helper method to build processing indicators
  Widget _buildProcessingIndicator(String label, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 4,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2000),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(2),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: EvacuationColors.subtitleColor,
          ),
        ),
      ],
    );
  }
}
