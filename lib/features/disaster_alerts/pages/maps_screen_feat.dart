import 'package:disaster_management/features/disaster_alerts/widgets/headerComponent.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:disaster_management/services/location_service.dart'; // Import the service file

class EvacuationScreen extends StatefulWidget {
  const EvacuationScreen({super.key});

  @override
  _EvacuationScreenState createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen> {
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  /// Request location permission
  Future<void> _fetchCurrentLocation() async {
  var locationData = await LocationService.getCurrentLocation(context);
  print("locationData: $locationData");

  if (locationData != null) {
    setState(() {
      _currentPosition = LatLng(
        locationData["latitude"] as double,
        locationData["longitude"] as double,
      );
    });

    if (mapController != null && _currentPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  } else {
    setState(() => _locationPermissionDenied = true);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          const HeaderComponent(), // Your existing header
          Expanded(
            child: Column(
              children: [
                // Map Container
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
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
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition!,
                                zoom: 14.0,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                            ),
                ),

                // Routes List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3, // Static demo data
                    itemBuilder: (context, index) => _buildRouteCard(index),
                  ),
                ),
              ],
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

  Widget _buildRouteCard(int index) {
    final routes = [
      {
        'destination': 'Delhi Emergency Shelter #1',
        'distance': '5.2 km',
        'duration': '15 mins',
        'traffic': 'Low',
      },
      {
        'destination': 'Government Hospital',
        'distance': '7.8 km',
        'duration': '22 mins',
        'traffic': 'Medium',
      },
      {
        'destination': 'Police Station HQ',
        'distance': '3.4 km',
        'duration': '10 mins',
        'traffic': 'High',
      },
    ];

    final route = routes[index];

    return Container(
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
          route['destination']!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  icon: Icons.timer,
                  text: route['duration']!,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  icon: Icons.directions_car,
                  text: route['distance']!,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      {required IconData icon, required String text, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}