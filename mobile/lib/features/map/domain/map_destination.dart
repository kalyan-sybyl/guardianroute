import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDestination {
  const MapDestination({
    required this.placeId,
    required this.label,
    required this.location,
  });

  final String placeId;
  final String label;
  final LatLng location;
}
