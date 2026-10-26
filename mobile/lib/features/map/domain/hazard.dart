import 'package:google_maps_flutter/google_maps_flutter.dart';

enum HazardSeverity {
  low,
  moderate,
  high,
  critical;

  static HazardSeverity fromString(String? value) {
    return HazardSeverity.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => HazardSeverity.moderate,
    );
  }

  String get label => name.toUpperCase();
}

enum HazardStatus {
  active,
  detected,
  reported,
  verified,
  stale,
  resolved;

  static HazardStatus fromString(String? value) {
    final normalized = value?.toUpperCase();
    return HazardStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == normalized,
      orElse: () => HazardStatus.active,
    );
  }
}

class Hazard {
  const Hazard({
    required this.id,
    required this.publicId,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.status,
    required this.location,
    required this.description,
    this.recommendedAction,
    this.isDemo = false,
  });

  final String id;
  final String publicId;
  final String type;
  final HazardSeverity severity;
  final double confidence;
  final HazardStatus status;
  final LatLng location;
  final String description;
  final String? recommendedAction;
  final bool isDemo;
}
