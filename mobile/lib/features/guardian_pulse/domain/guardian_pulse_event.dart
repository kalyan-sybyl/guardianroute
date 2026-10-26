import 'package:google_maps_flutter/google_maps_flutter.dart';

enum GuardianPulseStatus {
  emerging,
  active,
  resolved;

  static GuardianPulseStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'EMERGING':
        return GuardianPulseStatus.emerging;
      case 'ACTIVE':
        return GuardianPulseStatus.active;
      case 'RESOLVED':
        return GuardianPulseStatus.resolved;
      default:
        return GuardianPulseStatus.emerging;
    }
  }

  String get label => name.toUpperCase();
}

class GuardianPulseEvent {
  const GuardianPulseEvent({
    required this.id,
    required this.status,
    required this.confidence,
    required this.eventCount,
    required this.dominantEventType,
    required this.location,
    required this.radiusMeters,
    this.hazardId,
    this.isDemo = false,
  });

  final String id;
  final GuardianPulseStatus status;
  final double confidence;
  final int eventCount;
  final String dominantEventType;
  final LatLng location;
  final double radiusMeters;
  final String? hazardId;
  final bool isDemo;
}
