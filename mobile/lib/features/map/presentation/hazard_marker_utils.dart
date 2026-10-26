import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';

double hazardMarkerHue(HazardSeverity severity) {
  switch (severity) {
    case HazardSeverity.low:
      return BitmapDescriptor.hueGreen;
    case HazardSeverity.moderate:
      return BitmapDescriptor.hueYellow;
    case HazardSeverity.high:
      return BitmapDescriptor.hueOrange;
    case HazardSeverity.critical:
      return BitmapDescriptor.hueRed;
  }
}

Marker hazardToMarker(Hazard hazard, {void Function(Hazard)? onTap}) {
  return Marker(
    markerId: MarkerId(hazard.id),
    position: hazard.location,
    icon: BitmapDescriptor.defaultMarkerWithHue(hazardMarkerHue(hazard.severity)),
    infoWindow: InfoWindow(
      title: '${hazard.publicId} · ${hazard.type}',
      snippet: '${hazard.severity.label} · '
          '${(hazard.confidence * 100).round()}% confidence',
    ),
    onTap: onTap == null ? null : () => onTap(hazard),
  );
}
