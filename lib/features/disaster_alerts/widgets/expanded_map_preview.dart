import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/evacuation_place.dart';
import '../constants/colors.dart';
import 'evacuation_map.dart';

class ExpandedMapPreview extends StatelessWidget {
  final EvacuationPlace place;
  final LatLng currentPosition;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;

  const ExpandedMapPreview({
    super.key,
    required this.place,
    required this.currentPosition,
    required this.polylines,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Preview',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: EvacuationColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: EvacuationColors.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: EvacuationMap(
                currentPosition: currentPosition,
                places: [place],
                polylines: polylines,
                onMapCreated: onMapCreated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}