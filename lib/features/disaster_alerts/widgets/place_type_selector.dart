import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/place_type.dart';

class PlaceTypeSelector extends StatelessWidget {
  final PlaceType selectedPlaceType;
  final Function(PlaceType) onTypeSelected;

  const PlaceTypeSelector({
    Key? key,
    required this.selectedPlaceType,
    required this.onTypeSelected,
  }) : super(key: key);

  String _getAnimationAsset(PlaceType type) {
    switch (type) {
      case PlaceType.hospital:
        return 'assets/animations/hospital_ambulance.json';  // Updated animation
      case PlaceType.police:
        return 'assets/animations/police_bike.json';
      case PlaceType.fire:
        return 'assets/animations/fire_station.json';
      case PlaceType.shelter:
        return 'assets/animations/shelter.json';
      default:
        return 'assets/animations/general_alert.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8), // Adjusted padding
        itemCount: PlaceType.values.length,
        itemBuilder: (context, index) {
          final type = PlaceType.values[index];
          final isSelected = type == selectedPlaceType;
          final isFirst = index == 0;
          final isLast = index == PlaceType.values.length - 1;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(
              left: isFirst ? 8 : 12,
              right: isLast ? 8 : 12,
              top: 8,
              bottom: 8,
            ),
            child: Material(
              color: isSelected ? Colors.blue.shade500 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              elevation: isSelected ? 8 : 2,
              shadowColor: isSelected ? Colors.blue.withOpacity(0.4) : Colors.black12,
              child: InkWell(
                onTap: () => onTypeSelected(type),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  constraints: const BoxConstraints(minWidth: 160), // Added minimum width
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade300 : Colors.grey.withOpacity(0.1),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Added to prevent stretching
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Lottie.asset(
                          _getAnimationAsset(type),
                          fit: BoxFit.contain,
                          animate: isSelected,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          type.label,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}