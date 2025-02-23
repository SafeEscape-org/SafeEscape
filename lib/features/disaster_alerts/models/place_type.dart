import 'package:flutter/material.dart';
enum PlaceType {
  hospital('hospital', 'Hospitals', Icons.local_hospital),
  police('police', 'Police Stations', Icons.local_police),
  fire('fire_station', 'Fire Stations', Icons.fire_truck),
  shelter('shelter', 'Emergency Shelters', Icons.house),
  pharmacy('pharmacy', 'Pharmacies', Icons.local_pharmacy);

  final String value;
  final String label;
  final IconData icon;

  const PlaceType(this.value, this.label, this.icon);
}