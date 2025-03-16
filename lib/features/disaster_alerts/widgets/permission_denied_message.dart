import 'package:disaster_management/services/location_service.dart';
import 'package:flutter/material.dart';

class PermissionDeniedMessage extends StatelessWidget {
  final BuildContext parentContext;

  const PermissionDeniedMessage({
    super.key,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => LocationService.getCurrentLocation(parentContext),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}