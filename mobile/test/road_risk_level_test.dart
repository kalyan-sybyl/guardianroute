import 'package:flutter_test/flutter_test.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';

void main() {
  test('RoadRiskLevel.fromScore maps bands', () {
    expect(RoadRiskLevel.fromScore(10), RoadRiskLevel.low);
    expect(RoadRiskLevel.fromScore(40), RoadRiskLevel.moderate);
    expect(RoadRiskLevel.fromScore(60), RoadRiskLevel.high);
    expect(RoadRiskLevel.fromScore(90), RoadRiskLevel.critical);
  });
}
