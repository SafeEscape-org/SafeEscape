import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';

class EvacuationMap extends StatelessWidget {
  final LatLng currentPosition;
  final List<EvacuationPlace> places;
  final Function(GoogleMapController) onMapCreated;
  late GoogleMapController _mapController;
  EvacuationMap({
    Key? key,
    required this.currentPosition,
    required this.places,
    required this.onMapCreated,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: currentPosition,
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            onMapCreated(controller);
            _setMapStyle(controller);
          },
          markers: _createMarkers(),
        ),
        // Custom Controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.black87),
                onPressed: () {
                  _mapController.animateCamera(CameraUpdate.zoomIn());
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 4,
                child: const Icon(Icons.remove, color: Colors.black87),
                onPressed: () {
                  _mapController.animateCamera(CameraUpdate.zoomOut());
                },
              ),
            ],
          ),
        ),
        // Location Button
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            backgroundColor: Colors.white.withOpacity(0.9),
            elevation: 4,
            child: const Icon(Icons.my_location, color: Colors.black87),
            onPressed: () {
              _mapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: currentPosition,
                    zoom: 15.0,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    controller.setMapStyle('''
      [
        {
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "elementType": "labels.icon",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#757575"
            },
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry.fill",
          "stylers": [
            {
              "color": "#2c2c2c"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#8a8a8a"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#000000"
            }
          ]
        }
      ]
    ''');
  }

  Set<Marker> _createMarkers() {
    final Set<Marker> markers = {};
    
    // Add place markers
    for (var place in places) {
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

    // Add current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    return markers;
  }
}