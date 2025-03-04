import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/place_type.dart';

class PlaceTypeSelector extends StatelessWidget {
  final PlaceType selectedPlaceType;
  final Function(PlaceType) onTypeSelected;

  const PlaceTypeSelector({
    Key? key,
    required this.selectedPlaceType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: PlaceType.values.length,
        itemBuilder: (context, index) {
          final type = PlaceType.values[index];
          final isSelected = type == selectedPlaceType;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: isSelected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isSelected ? 0 : 0.5,
              child: InkWell(
                onTap: () => onTypeSelected(type),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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