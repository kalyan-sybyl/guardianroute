import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';

class HazardProximityAlert {
  const HazardProximityAlert({
    required this.hazard,
    required this.distanceMeters,
  });

  final Hazard hazard;
  final int distanceMeters;

  String get headline => 'DANGER AHEAD';

  String get subtitle => hazard.type.replaceAll('_', ' ').toUpperCase();

  String get actionLabel => 'REDUCE SPEED';
}

/// Hazards worth interrupting navigation for.
bool hazardEligibleForWarning(Hazard hazard) {
  if (hazard.status == HazardStatus.resolved ||
      hazard.status == HazardStatus.stale) {
    return false;
  }
  return hazard.severity == HazardSeverity.high ||
      hazard.severity == HazardSeverity.critical ||
      (hazard.severity == HazardSeverity.moderate && hazard.confidence >= 0.7);
}

HazardProximityAlert? findNearestRouteHazard({
  required LatLng user,
  required List<LatLng> routePolyline,
  required List<Hazard> hazards,
  required double warningDistanceMeters,
  double routeCorridorMeters = 120,
}) {
  if (routePolyline.isEmpty || hazards.isEmpty) return null;

  Hazard? best;
  double bestDistance = double.infinity;

  for (final hazard in hazards) {
    if (!hazardEligibleForWarning(hazard)) continue;

    final distToUser = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      hazard.location.latitude,
      hazard.location.longitude,
    );
    if (distToUser > warningDistanceMeters) continue;

    final distToRoute = distancePointToPolylineMeters(
      hazard.location,
      routePolyline,
    );
    if (distToRoute > routeCorridorMeters) continue;

    if (distToUser < bestDistance) {
      bestDistance = distToUser;
      best = hazard;
    }
  }

  if (best == null) return null;

  return HazardProximityAlert(
    hazard: best,
    distanceMeters: bestDistance.round().clamp(0, warningDistanceMeters.round()),
  );
}

double distancePointToPolylineMeters(LatLng point, List<LatLng> polyline) {
  if (polyline.isEmpty) return double.infinity;
  if (polyline.length == 1) {
    return Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      polyline.first.latitude,
      polyline.first.longitude,
    );
  }

  var min = double.infinity;
  for (var i = 0; i < polyline.length - 1; i++) {
    final d = distancePointToSegmentMeters(
      point,
      polyline[i],
      polyline[i + 1],
    );
    if (d < min) min = d;
  }
  return min;
}

double distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  final ax = a.longitude;
  final ay = a.latitude;
  final bx = b.longitude;
  final by = b.latitude;
  final px = p.longitude;
  final py = p.latitude;

  final dx = bx - ax;
  final dy = by - ay;
  if (dx == 0 && dy == 0) {
    return Geolocator.distanceBetween(py, px, ay, ax);
  }

  final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
  final clamped = t.clamp(0.0, 1.0);
  final projLat = ay + clamped * dy;
  final projLng = ax + clamped * dx;

  return Geolocator.distanceBetween(py, px, projLat, projLng);
}

/// Approximate meters left along [polyline] from [user] to the end.
double remainingDistanceAlongPolylineMeters(
  LatLng user,
  List<LatLng> polyline,
) {
  if (polyline.length < 2) {
    if (polyline.isEmpty) return 0;
    return Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      polyline.last.latitude,
      polyline.last.longitude,
    );
  }

  var closestSegment = 0;
  var minDist = double.infinity;
  for (var i = 0; i < polyline.length - 1; i++) {
    final d = distancePointToSegmentMeters(user, polyline[i], polyline[i + 1]);
    if (d < minDist) {
      minDist = d;
      closestSegment = i;
    }
  }

  var remaining = Geolocator.distanceBetween(
    user.latitude,
    user.longitude,
    polyline[closestSegment + 1].latitude,
    polyline[closestSegment + 1].longitude,
  );

  for (var i = closestSegment + 1; i < polyline.length - 1; i++) {
    remaining += Geolocator.distanceBetween(
      polyline[i].latitude,
      polyline[i].longitude,
      polyline[i + 1].latitude,
      polyline[i + 1].longitude,
    );
  }

  return remaining;
}
