import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';

enum RouteLabel {
  fastest,
  balanced,
  safest;

  static RouteLabel fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'FASTEST':
        return RouteLabel.fastest;
      case 'SAFEST':
        return RouteLabel.safest;
      default:
        return RouteLabel.balanced;
    }
  }

  String get wireName => name.toUpperCase();
}

class RouteOption {
  const RouteOption({
    required this.routeId,
    required this.label,
    required this.durationMinutes,
    required this.distanceKm,
    required this.riskScore,
    required this.riskLevel,
    required this.encodedPolyline,
    required this.summary,
  });

  final String routeId;
  final RouteLabel label;
  final int durationMinutes;
  final double distanceKm;
  final int riskScore;
  final RoadRiskLevel riskLevel;
  final String encodedPolyline;
  final String summary;

  factory RouteOption.fromMap(Map<String, dynamic> map) {
    return RouteOption(
      routeId: map['routeId'] as String,
      label: RouteLabel.fromWire(map['label'] as String?),
      durationMinutes: (map['durationMinutes'] as num).toInt(),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      riskScore: (map['riskScore'] as num).toInt(),
      riskLevel: RoadRiskLevel.fromString(map['riskLevel'] as String?),
      encodedPolyline: map['encodedPolyline'] as String,
      summary: map['summary'] as String? ?? 'Route',
    );
  }
}

class RoutePlanResult {
  const RoutePlanResult({
    required this.routes,
    required this.recommendationMessage,
    required this.recommendedLabel,
    required this.isDemo,
  });

  final List<RouteOption> routes;
  final String recommendationMessage;
  final RouteLabel recommendedLabel;
  final bool isDemo;
}

class SelectedRoute {
  const SelectedRoute({
    required this.option,
    required this.polylinePoints,
    required this.destinationLabel,
  });

  final RouteOption option;
  final List<LatLng> polylinePoints;
  final String destinationLabel;
}
