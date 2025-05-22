import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';
import 'package:disaster_management/features/disaster_alerts/models/evacuation_place.dart';
import 'package:disaster_management/features/disaster_alerts/services/places_service.dart';
import 'package:disaster_management/features/disaster_alerts/utils/map_bounds_calculator.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/expanded_actions.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/expanded_map_preview.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/permission_denied_message.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/place_type_selector.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/SideNavigation/side_navigation.dart';
import 'package:disaster_management/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:disaster_management/services/location_service.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/evacuation_map.dart';
import 'package:disaster_management/shared/widgets/chat_assistance.dart';
import '../models/place_type.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
//cicd checks code ql fi
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
  Set<Polyline> _polylines = {};
  PlaceType _selectedPlaceType = PlaceType.hospital;
  String _locationName = "Finding location..."; // Add this variable
  Set<Marker> _markers = {}; // Add this line to store markers
  //chunking
  final int _initialLoadCount = 5;
  List<EvacuationPlace> _displayedPlaces = [];
  bool _isLoadingMore = false;
  String? _nextPageToken;
  final ScrollController _placesScrollController = ScrollController();
  List<EvacuationPlace> _allPlaces = [];
  bool _isMapExpanded = false;
  
  // Helper methods for route information
  String _calculateRouteDistance() {
    // In a real app, this would calculate the actual distance
    // For now, return a placeholder value
    return '3.2';
  }
  
  String _calculateRouteDuration() {
    // In a real app, this would calculate the actual duration
    // For now, return a placeholder value
    return '12';
  }
  
  void _clearRoute() {
    setState(() {
      _polylines.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _placesScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _placesScrollController.removeListener(_scrollListener);
    _placesScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_placesScrollController.position.pixels >=
            _placesScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePlaces();
    }
  }

//must for frintend side  by location service as common location services server file
  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    try {
      final locationData = await LocationService.getCurrentLocation(context);
      if (locationData != null) {
        final position = LatLng(
          locationData["latitude"] as double,
          locationData["longitude"] as double,
        );

        // Get address from coordinates
        final address = await LocationService.getAddressFromCoordinates(
          locationData["latitude"] as double,
          locationData["longitude"] as double,
        );

        setState(() {
          _currentPosition = position;
          _locationName = address ?? "Unknown Location"; // Set location name
        });
        await _fetchNearbyPlaces(); //this will by default fetch hosppitls
      } else {
        setState(() => _locationPermissionDenied = true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _allPlaces = [];
      _displayedPlaces = [];
      _nextPageToken = null;
      _markers = {}; // Clear existing markers
      _polylines = {}; // Clear existing polylines
    });

    try {
      final result = await PlacesService.getNearbyPlacesWithToken(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        type: _selectedPlaceType.value,
      );

      final places = result['places'] as List<EvacuationPlace>;
      _nextPageToken = result['next_page_token'];

      // Generate enhanced markers for places
      final markers = await _generateEnhancedMarkers(
        places: places,
        currentPosition: _currentPosition!,
      );

      setState(() {
        _allPlaces = places;
        _displayedPlaces = places.take(_initialLoadCount).toList();
        _places = places; // Update _places list for the map
        _markers = markers; // Set the markers
      });
    } catch (e) {
      // ... existing error handling ...
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //more places loader added by self logic
  Future<void> _loadMorePlaces() async {
    // If we've already displayed all places from the current batch
    if (_displayedPlaces.length < _allPlaces.length) {
      setState(() {
        final remainingPlaces = _allPlaces.length - _displayedPlaces.length;
        final itemsToAdd = remainingPlaces > 5 ? 5 : remainingPlaces;
        _displayedPlaces.addAll(_allPlaces.getRange(
            _displayedPlaces.length, _displayedPlaces.length + itemsToAdd));
      });
      return;
    }

    // If we need to fetch more from the API
    if (_nextPageToken != null) {
      setState(() => _isLoadingMore = true);

      try {
        final result = await PlacesService.getNearbyPlacesWithToken(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          type: _selectedPlaceType.value,
          pageToken: _nextPageToken,
        );

        final newPlaces = result['places'] as List<EvacuationPlace>;

        setState(() {
          _nextPageToken = result['next_page_token'];
          _allPlaces.addAll(newPlaces);
          _displayedPlaces.addAll(newPlaces.take(5).toList());
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more places: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoadingMore = false);
      }
    }
  }

   // New method to generate enhanced markers
  Future<Set<Marker>> _generateEnhancedMarkers({
    required List<EvacuationPlace> places,
    required LatLng currentPosition,
  }) async {
    final Set<Marker> markers = {};
    
    // Add current location marker
    final currentLocationMarker = await _createCustomMarker(
      id: 'current_location',
      position: currentPosition,
      title: 'Your Location',
      snippet: _locationName,
      iconData: Icons.my_location,
      color: Colors.blue,
      isCurrentLocation: true,
    );
    markers.add(currentLocationMarker);
    
    // Add place markers
    for (var place in places) {
      final placeMarker = await _createCustomMarker(
        id: place.placeId,
        position: LatLng(place.lat, place.lng),
        title: place.name,
        snippet: place.vicinity,
        iconData: _selectedPlaceType.icon,
        color: EvacuationColors.primaryColor,
        rating: place.rating,
        onTap: () => _showRouteToPlace(place),
      );
      markers.add(placeMarker);
    }
    
    return markers;
  }

  // Helper method to create custom marker
  Future<Marker> _createCustomMarker({
    required String id,
    required LatLng position,
    required String title,
    required String snippet,
    required IconData iconData,
    required Color color,
    double? rating,
    bool isCurrentLocation = false,
    VoidCallback? onTap,
  }) async {
    // Create custom marker icon
    final BitmapDescriptor markerIcon = await _createMarkerBitmap(
      iconData: iconData,
      color: color,
      rating: rating,
      isCurrentLocation: isCurrentLocation,
    );
    
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: markerIcon,
      onTap: onTap,
      zIndex: isCurrentLocation ? 2 : 1, // Current location appears on top
    );
  }
  
  // Create custom marker bitmap
  Future<BitmapDescriptor> _createMarkerBitmap({
    required IconData iconData,
    required Color color,
    double? rating,
    bool isCurrentLocation = false,
  }) async {
    // For simplicity, we'll use default markers with custom hues for now
    // In a production app, you would use a custom widget and RepaintBoundary
    // to create truly custom markers with ratings, etc.
    
    if (isCurrentLocation) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    
    // Use different hues based on place type or rating
    double hue = BitmapDescriptor.hueRed;
    
    switch (_selectedPlaceType) {
      case PlaceType.hospital:
        hue = BitmapDescriptor.hueRed;
        break;
      case PlaceType.police:
        hue = BitmapDescriptor.hueBlue;
        break;
      case PlaceType.fire:
        hue = BitmapDescriptor.hueOrange;
        break;
      case PlaceType.shelter:
        hue = BitmapDescriptor.hueViolet;
        break;
      default:
        hue = BitmapDescriptor.hueRose;
    }
    
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // If map is expanded, show full-screen map
    if (_isMapExpanded) {
      return Scaffold(
        body: Stack(
          children: [
            // Full-screen map - use entire screen
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: _currentPosition == null
                  ? _buildLoadingIndicator()
                  : EvacuationMap(
                      currentPosition: _currentPosition!,
                      places: _places,
                      polylines: _polylines,
                      markers: _markers,
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                    ),
            ),
            
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
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
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleMapExpansion,
                ),
              ),
            ),
            
            // Add a floating route info panel at the bottom
            if (_polylines.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Route to Destination',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: EvacuationColors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_calculateRouteDistance()} km • ${_calculateRouteDuration()} min',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: EvacuationColors.subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearRoute,
                            color: Colors.red[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Start navigation logic
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // Regular view with small map
    return Stack(
      children: [
        AppScaffold(
          title: "Safety & Evacuation", // Add this custom title
          locationName: _locationPermissionDenied
              ? "Location access denied"
              : _currentPosition == null
                  ? "Finding location..."
                  : _locationName,
          backgroundColor: EvacuationColors.backgroundColor,
          drawer: const SideNavigation(userName: 'abc'),
          body: RefreshIndicator(
            onRefresh: _fetchNearbyPlaces,
            color: EvacuationColors.primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Safe Places',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: EvacuationColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PlaceTypeSelector(
                          selectedPlaceType: _selectedPlaceType,
                          onTypeSelected: (type) {
                            setState(() => _selectedPlaceType = type);
                            _fetchNearbyPlaces();
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: _showExpandedMap,
                    child: Container(
                      height: screenHeight * 0.4,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EvacuationColors.cardBackground,
                            EvacuationColors.cardBackground.withOpacity(0.8),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white10,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          _locationPermissionDenied
                              ? _buildPermissionDeniedMessage()
                              : _currentPosition == null
                                  ? _buildLoadingIndicator()
                                  : GestureDetector(
                                      onTap: _toggleMapExpansion,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: EvacuationMap(
                                          currentPosition: _currentPosition!,
                                          places: _places,
                                          polylines: _polylines,
                                          markers: _markers, // Pass the markers
                                          onMapCreated: (controller) {
                                            mapController = controller;
                                          },
                                        ),
                                      ),
                                    ),
                          // Map controls remain the same
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Column(
                              children: [
                                _buildMapButton(
                                  icon: Icons.add,
                                  onPressed: () => mapController.animateCamera(
                                    CameraUpdate.zoomIn(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildMapButton(
                                  icon: Icons.remove,
                                  onPressed: () => mapController.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: _buildMapButton(
                              icon: Icons.my_location,
                              onPressed: () {
                                if (_currentPosition != null) {
                                  mapController.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      _currentPosition!,
                                      15,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: EvacuationColors.cardBackground,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nearby Places',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: EvacuationColors.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPlacesList(),
              ],
            ),
          ),
        ),

        // Add the ChatAssistance as a positioned widget
        const Positioned(
          right: 16,
          bottom: 16,
          child: ChatAssistance(),
        ),
      ],
    );
  }

  Widget _buildPlacesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: _displayedPlaces.isEmpty
          ? SliverFillRemaining(
              child: _isLoading ? _buildLoadingIndicator() : _buildEmptyState())
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Show places
                  if (index < _displayedPlaces.length) {
                    return _buildRouteCard(_displayedPlaces[index]);
                  }

                  // Show loading indicator or load more button
                  if (_isLoadingMore) {
                    return _buildLoadingMoreIndicator();
                  } else if (_displayedPlaces.length < _allPlaces.length ||
                      _nextPageToken != null) {
                    return _buildLoadMoreButton();
                  }

                  return null;
                },
                childCount: _displayedPlaces.length +
                    ((_displayedPlaces.length < _allPlaces.length ||
                            _nextPageToken != null)
                        ? 1
                        : 0),
              ),
            ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: _loadMorePlaces,
        icon: const Icon(Icons.refresh),
        label: const Text("Load More Places"),
        style: ElevatedButton.styleFrom(
          backgroundColor: EvacuationColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        valueColor:
            AlwaysStoppedAnimation<Color>(EvacuationColors.primaryColor),
        strokeWidth: 3,
      ),
    );
  }

  void _showExpandedMap() {
    _toggleMapExpansion();
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
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
        onPressed: onPressed,
        color: Colors.black87,
        iconSize: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: EvacuationColors.textColor,
                fontSize: 13,
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

  Widget _buildRouteCard(EvacuationPlace place) {
    IconData placeIcon = _selectedPlaceType.icon;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: EvacuationColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        shadowColor: EvacuationColors.shadowColor.withOpacity(0.3),
        child: InkWell(
          onTap: () => _showRouteToPlace(place),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: EvacuationColors.borderColor.withOpacity(0.7),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  EvacuationColors.cardBackground,
                  EvacuationColors.cardBackground.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EvacuationColors.primaryColor.withOpacity(0.2),
                        EvacuationColors.accentColor.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: EvacuationColors.primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    placeIcon,
                    color: EvacuationColors.primaryColor,
                    size: isSmallScreen ? 18 : 22,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          color: EvacuationColors.textColor,
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Wrap(
                        spacing: isSmallScreen ? 4 : 6,
                        runSpacing: isSmallScreen ? 4 : 6,
                        children: [
                          if (place.rating != null)
                            _buildCompactInfoChip(
                              icon: Icons.star_rounded,
                              text: place.rating!.toString(),
                              color: const Color(0xFFFB923C),
                              isSmallScreen: isSmallScreen,
                              maxWidth:
                                  screenWidth * (isSmallScreen ? 0.15 : 0.2),
                            ),
                          _buildCompactInfoChip(
                            icon: Icons.location_on_rounded,
                            text: place.vicinity,
                            color: EvacuationColors.primaryColor,
                            isSmallScreen: isSmallScreen,
                            maxWidth:
                                screenWidth * (isSmallScreen ? 0.35 : 0.45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Hero(
                  tag: 'arrow_${place.placeId}',
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: EvacuationColors.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: EvacuationColors.primaryColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: EvacuationColors.primaryColor,
                      size: isSmallScreen ? 10 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // More compact info chip for all screen sizes
  Widget _buildCompactInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    required bool isSmallScreen,
    required double maxWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 10 : 14,
          ),
          SizedBox(width: isSmallScreen ? 3 : 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: EvacuationColors.textColor,
                fontSize: isSmallScreen ? 10 : 12,
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

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildPermissionDeniedMessage() {
    return PermissionDeniedMessage(parentContext: context);
  }

  Widget _buildExpandedHeader(EvacuationPlace place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: EvacuationColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: EvacuationColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EvacuationColors.textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Hero(
                tag: 'icon_${place.placeId}',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EvacuationColors.primaryColor.withOpacity(0.1),
                        EvacuationColors.accentColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _selectedPlaceType.icon,
                    color: EvacuationColors.primaryColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'name_${place.placeId}',
                      child: Text(
                        place.name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: EvacuationColors.textColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (place.rating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < (place.rating ?? 0).floor()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFB923C),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(EvacuationPlace place) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: EvacuationColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EvacuationColors.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.location_on_rounded,
                  'Address',
                  place.vicinity,
                ),
                if (place.rating != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.star_rounded,
                    'Rating',
                    '${place.rating} / 5.0',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EvacuationColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: EvacuationColors.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: EvacuationColors.subtitleColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: EvacuationColors.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedMap(EvacuationPlace place) {
    return ExpandedMapPreview(
      place: place,
      currentPosition: _currentPosition!,
      polylines: _polylines,
      onMapCreated: (controller) => mapController = controller,
    );
  }

  Widget _buildExpandedActions(EvacuationPlace place) {
    return ExpandedActions(
      onNavigationStart: () {
        // Add navigation logic here
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showRouteToPlace(EvacuationPlace place) async {
    // Show expanded view first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: EvacuationColors.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: EvacuationColors.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildExpandedHeader(place),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExpandedDetails(place),
                          _buildExpandedMap(place),
                          _buildExpandedActions(place),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Fetch and display route
    try {
      final polylinePoints = await PlacesService.getDirections(
        origin: _currentPosition!,
        destination: LatLng(place.lat, place.lng),
      );

      if (polylinePoints.isNotEmpty) {
        final String polylineId = 'route_${place.placeId}';
        final Polyline routePolyline = Polyline(
          polylineId: PolylineId(polylineId),
          points: polylinePoints,
          color: EvacuationColors.primaryColor,
          width: 5,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(routePolyline);
        });
        
        // If map is expanded, show the route info panel
        if (_isMapExpanded) {
          // Already showing the route info panel via the if condition in the UI
        } else {
          // Consider expanding the map to show the route
          _toggleMapExpansion();
        }
        
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            MapBoundsCalculator.getRouteLatLngBounds(polylinePoints),
            50,
          ),
        );
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
}
