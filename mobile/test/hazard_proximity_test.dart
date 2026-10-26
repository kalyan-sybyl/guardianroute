import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';
import 'package:guardianroute/features/navigation/domain/hazard_proximity.dart';

void main() {
  test('findNearestRouteHazard ignores hazards far from route', () {
    const user = LatLng(0.3136, 32.5811);
    const route = [
      LatLng(0.3130, 32.5800),
      LatLng(0.3140, 32.5820),
    ];
    final hazards = [
      Hazard(
        id: 'off-route',
        publicId: 'H1',
        type: 'pothole',
        severity: HazardSeverity.critical,
        confidence: 0.95,
        status: HazardStatus.active,
        location: const LatLng(0.32, 32.59),
        description: 'Far away',
      ),
    ];

    final alert = findNearestRouteHazard(
      user: user,
      routePolyline: route,
      hazards: hazards,
      warningDistanceMeters: 500,
    );

    expect(alert, isNull);
  });

  test('findNearestRouteHazard returns closest eligible hazard', () {
    const user = LatLng(0.3136, 32.5811);
    const route = [
      LatLng(0.3130, 32.5800),
      LatLng(0.3140, 32.5820),
    ];
    final hazards = [
      Hazard(
        id: 'near',
        publicId: 'H2',
        type: 'pothole',
        severity: HazardSeverity.high,
        confidence: 0.9,
        status: HazardStatus.active,
        location: const LatLng(0.3137, 32.5812),
        description: 'On path',
      ),
      Hazard(
        id: 'farther',
        publicId: 'H3',
        type: 'debris',
        severity: HazardSeverity.critical,
        confidence: 0.99,
        status: HazardStatus.active,
        location: const LatLng(0.3145, 32.5825),
        description: 'Also on path',
      ),
    ];

    final alert = findNearestRouteHazard(
      user: user,
      routePolyline: route,
      hazards: hazards,
      warningDistanceMeters: 400,
      routeCorridorMeters: 200,
    );

    expect(alert, isNotNull);
    expect(alert!.hazard.id, 'near');
  });
}
