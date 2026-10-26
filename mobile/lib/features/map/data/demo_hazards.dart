import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';

/// Sample hazards around Kampala for empty Firestore / demo storytelling.
List<Hazard> kampalaDemoHazards() {
  const center = MapConstants.kampalaCenter;
  return [
    Hazard(
      id: 'demo-1',
      publicId: 'GR-D01',
      type: 'POTHOLE',
      severity: HazardSeverity.high,
      confidence: 0.94,
      status: HazardStatus.active,
      location: LatLng(center.latitude + 0.008, center.longitude + 0.012),
      description: 'Large pothole affecting the motorcycle travel path.',
      recommendedAction: 'Reduce speed and avoid the damaged section when safe.',
      isDemo: true,
    ),
    Hazard(
      id: 'demo-2',
      publicId: 'GR-D02',
      type: 'ROAD_DAMAGE',
      severity: HazardSeverity.moderate,
      confidence: 0.78,
      status: HazardStatus.active,
      location: LatLng(center.latitude - 0.006, center.longitude - 0.009),
      description: 'Uneven road surface near junction.',
      isDemo: true,
    ),
    Hazard(
      id: 'demo-3',
      publicId: 'GR-D03',
      type: 'DANGEROUS_INTERSECTION',
      severity: HazardSeverity.critical,
      confidence: 0.88,
      status: HazardStatus.verified,
      location: LatLng(center.latitude + 0.004, center.longitude - 0.015),
      description: 'Poor visibility and heavy merging traffic.',
      recommendedAction: 'Proceed with extreme caution.',
      isDemo: true,
    ),
  ];
}
