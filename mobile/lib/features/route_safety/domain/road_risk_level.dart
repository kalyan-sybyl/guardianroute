enum RoadRiskLevel {
  low,
  moderate,
  high,
  critical;

  static RoadRiskLevel fromScore(int score) {
    if (score <= 25) return RoadRiskLevel.low;
    if (score <= 50) return RoadRiskLevel.moderate;
    if (score <= 75) return RoadRiskLevel.high;
    return RoadRiskLevel.critical;
  }

  static RoadRiskLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return RoadRiskLevel.low;
      case 'MODERATE':
        return RoadRiskLevel.moderate;
      case 'HIGH':
        return RoadRiskLevel.high;
      case 'CRITICAL':
        return RoadRiskLevel.critical;
      default:
        return RoadRiskLevel.moderate;
    }
  }

  String get wireName => name.toUpperCase();
}
