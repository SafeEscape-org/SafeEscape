import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/colors.dart';

class MapTypeSelector {
  static void show(BuildContext context, MapType currentMapType, Function(MapType) onMapTypeSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Select Map Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMapTypeOption(
              context,
              'Standard', 
              Icons.map_outlined, 
              MapType.normal,
              currentMapType,
              onMapTypeSelected,
            ),
            _buildMapTypeOption(
              context,
              'Satellite', 
              Icons.satellite_outlined, 
              MapType.satellite,
              currentMapType,
              onMapTypeSelected,
            ),
            _buildMapTypeOption(
              context,
              'Terrain', 
              Icons.terrain_outlined, 
              MapType.terrain,
              currentMapType,
              onMapTypeSelected,
            ),
            _buildMapTypeOption(
              context,
              'Hybrid', 
              Icons.layers_outlined, 
              MapType.hybrid,
              currentMapType,
              onMapTypeSelected,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMapTypeOption(
    BuildContext context,
    String title, 
    IconData icon, 
    MapType mapType,
    MapType currentMapType,
    Function(MapType) onMapTypeSelected,
  ) {
    final isSelected = currentMapType == mapType;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? EvacuationColors.primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? EvacuationColors.primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? const Icon(Icons.check, color: EvacuationColors.primaryColor) 
          : null,
      onTap: () {
        onMapTypeSelected(mapType);
        Navigator.pop(context);
      },
    );
  }
}