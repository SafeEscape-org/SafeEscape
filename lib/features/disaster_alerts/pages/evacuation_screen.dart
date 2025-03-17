import 'package:disaster_management/features/disaster_alerts/constants/colors.dart';
import 'package:disaster_management/features/disaster_alerts/models/evacuation_place.dart';
import 'package:disaster_management/features/disaster_alerts/services/places_service.dart';
import 'package:disaster_management/features/disaster_alerts/utils/map_bounds_calculator.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/expanded_actions.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/expanded_map_preview.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/permission_denied_message.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/place_type_selector.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/side_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:disaster_management/services/location_service.dart';
import 'package:disaster_management/features/disaster_alerts/widgets/evacuation_map.dart';
import 'package:disaster_management/shared/widgets/chat_assistance.dart';
import '../models/place_type.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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

    setState(() => _isLoading = true);
    try {
      final places = await PlacesService.getNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        type: _selectedPlaceType.value,
      );
      setState(() => _places = places);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch nearby places'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: EvacuationColors.backgroundColor,
      drawer: const SideNavigation(userName: 'abc'), // Add the drawer here
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Builder(  // Wrap with Builder to get correct context
                    builder: (BuildContext context) => HeaderComponent(
                      onMenuPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
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
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: EvacuationMap(
                                        currentPosition: _currentPosition!,
                                        places: _places,
                                        polylines: _polylines,
                                        onMapCreated: (controller) {
                                          mapController = controller;
                                        },
                                      ),
                                    ),
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
          const ChatAssistance(),
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: _places.isEmpty
          ? SliverFillRemaining(child: _buildEmptyState())
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRouteCard(_places[index]),
                childCount: _places.length,
              ),
            ),
    );
  }

  void _showExpandedMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: EvacuationColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: EvacuationColors.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: EvacuationMap(
                    currentPosition: _currentPosition!,
                    places: _places,
                    polylines: _polylines,
                    onMapCreated: (controller) => mapController = controller,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: EvacuationColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          onTap: () => _showRouteToPlace(place),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EvacuationColors.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EvacuationColors.primaryColor.withOpacity(0.1),
                        EvacuationColors.accentColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    placeIcon,
                    color: EvacuationColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.inter(
                          color: EvacuationColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (place.rating != null)
                            _buildInfoChip(
                              icon: Icons.star_rounded,
                              text: place.rating!.toString(),
                              color: const Color(0xFFFB923C),
                            ),
                          _buildInfoChip(
                            icon: Icons.location_on_rounded,
                            text: place.vicinity,
                            color: EvacuationColors.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Hero(
                  tag: 'arrow_${place.placeId}',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EvacuationColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: EvacuationColors.primaryColor,
                      size: 16,
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
// Remove the _getBoundsForRoute method and update where it's used
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
