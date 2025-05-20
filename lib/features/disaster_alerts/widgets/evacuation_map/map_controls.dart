import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';

class MapControls extends StatelessWidget {
  final bool isDarkMode;
  final bool trafficEnabled;
  final Function() onMapTypePressed;
  final Function() onTrafficToggled;
  final Function() onDarkModeToggled;
  final Function() onMyLocationPressed;

  const MapControls({
    Key? key,
    required this.isDarkMode,
    required this.trafficEnabled,
    required this.onMapTypePressed,
    required this.onTrafficToggled,
    required this.onDarkModeToggled,
    required this.onMyLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map type button
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              onMapTypePressed();
            },
          ),
          
          // Traffic toggle
          IconButton(
            icon: Icon(
              Icons.traffic_outlined,
              color: trafficEnabled 
                  ? EvacuationColors.primaryColor 
                  : Colors.grey[600],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              onTrafficToggled();
            },
          ),
          
          // Dark mode toggle
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: isDarkMode 
                  ? EvacuationColors.primaryColor 
                  : Colors.grey[600],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              onDarkModeToggled();
            },
          ),
          
          // My location button
          IconButton(
            icon: const Icon(Icons.my_location),
            color: EvacuationColors.primaryColor,
            onPressed: () {
              HapticFeedback.selectionClick();
              onMyLocationPressed();
            },
          ),
        ],
      ),
    );
  }
}