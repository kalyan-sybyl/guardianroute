import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';
import 'package:guardianroute/features/route_safety/domain/road_segment.dart';

List<RoadSegment> kampalaDemoRoadSegments() {
  const center = MapConstants.kampalaCenter;
  return [
    RoadSegment(
      id: 'demo-seg-high',
      geohash: 'demo-high',
      location: LatLng(center.latitude + 0.008, center.longitude + 0.012),
      riskScore: 78,
      riskLevel: RoadRiskLevel.high,
      isDemo: true,
    ),
    RoadSegment(
      id: 'demo-seg-mod',
      geohash: 'demo-mod',
      location: LatLng(center.latitude - 0.005, center.longitude - 0.008),
      riskScore: 44,
      riskLevel: RoadRiskLevel.moderate,
      isDemo: true,
    ),
  ];
}
