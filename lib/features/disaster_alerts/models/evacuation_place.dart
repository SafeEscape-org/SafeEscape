class EvacuationPlace {
  final String name;
  final double lat;
  final double lng;
  final String vicinity;
  final String placeId;
  final bool isOpen;
  final double? rating;
  final String? photoReference;

  EvacuationPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.vicinity,
    required this.placeId,
    required this.isOpen,
    this.rating,
    this.photoReference,
  });

  factory EvacuationPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    final openingHours = json['opening_hours'];
    final photos = json['photos'];

    return EvacuationPlace(
      name: json['name'],
      lat: geometry['lat'],
      lng: geometry['lng'],
      vicinity: json['vicinity'],
      placeId: json['place_id'],
      isOpen: openingHours?['open_now'] ?? false,
      rating: json['rating']?.toDouble(),
      photoReference: photos?[0]['photo_reference'],
    );
  }
}