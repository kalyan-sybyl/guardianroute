import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';

class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.geohash,
    required this.location,
    required this.riskScore,
    required this.riskLevel,
    this.isDemo = false,
  });

  final String id;
  final String geohash;
  final LatLng location;
  final int riskScore;
  final RoadRiskLevel riskLevel;
  final bool isDemo;
}
