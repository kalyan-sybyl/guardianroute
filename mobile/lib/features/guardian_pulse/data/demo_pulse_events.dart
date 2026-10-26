import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/features/guardian_pulse/domain/guardian_pulse_event.dart';

List<GuardianPulseEvent> kampalaDemoPulseEvents() {
  const center = MapConstants.kampalaCenter;
  return [
    GuardianPulseEvent(
      id: 'demo-pulse-1',
      status: GuardianPulseStatus.emerging,
      confidence: 0.86,
      eventCount: 38,
      dominantEventType: 'VERTICAL_SHOCK',
      location: LatLng(center.latitude + 0.007, center.longitude + 0.01),
      radiusMeters: 40,
      isDemo: true,
    ),
  ];
}
