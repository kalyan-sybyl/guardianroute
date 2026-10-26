import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';
import 'package:guardianroute/features/map/presentation/hazard_marker_utils.dart';

void main() {
  test('severity maps to expected marker hues', () {
    expect(hazardMarkerHue(HazardSeverity.low), BitmapDescriptor.hueGreen);
    expect(hazardMarkerHue(HazardSeverity.moderate), BitmapDescriptor.hueYellow);
    expect(hazardMarkerHue(HazardSeverity.high), BitmapDescriptor.hueOrange);
    expect(hazardMarkerHue(HazardSeverity.critical), BitmapDescriptor.hueRed);
  });
}
