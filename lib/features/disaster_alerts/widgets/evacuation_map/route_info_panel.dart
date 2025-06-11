import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class RouteInfoPanel extends StatelessWidget {
  final String routeDistance;
  final String routeDuration;
  final Function() onNavigate;

  const RouteInfoPanel({
    Key? key,
    required this.routeDistance,
    required this.routeDuration,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    '$routeDistance km • $routeDuration min',
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
            onPressed: onNavigate,
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
}