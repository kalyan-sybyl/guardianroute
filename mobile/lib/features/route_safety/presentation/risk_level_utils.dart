import 'package:flutter/material.dart';
import 'package:guardianroute/app/theme.dart';
import 'package:guardianroute/features/route_safety/domain/road_risk_level.dart';

Color riskLevelColor(RoadRiskLevel level) {
  switch (level) {
    case RoadRiskLevel.low:
      return GuardianColors.safetyGreen;
    case RoadRiskLevel.moderate:
      return GuardianColors.warmAmber;
    case RoadRiskLevel.high:
      return Colors.deepOrange;
    case RoadRiskLevel.critical:
      return GuardianColors.alertRed;
  }
}

Color riskScoreColor(int score) {
  return riskLevelColor(RoadRiskLevel.fromScore(score));
}

double riskCircleRadiusMeters(RoadRiskLevel level) {
  switch (level) {
    case RoadRiskLevel.low:
      return 55;
    case RoadRiskLevel.moderate:
      return 70;
    case RoadRiskLevel.high:
      return 85;
    case RoadRiskLevel.critical:
      return 100;
  }
}
