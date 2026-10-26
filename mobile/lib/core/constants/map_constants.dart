import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Kampala city centre — default map focus for GuardianRoute.
abstract final class MapConstants {
  static const kampalaCenter = LatLng(0.3476, 32.5825);

  static const defaultZoom = 13.0;

  static const userLocationZoom = 15.0;

  /// Uganda bounding bias for Places Autocomplete (approx.).
  static const placesLocationBias = kampalaCenter;

  static const placesRadiusMeters = 80000;
}
