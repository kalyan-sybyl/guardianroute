class SensorThresholds {
  const SensorThresholds({
    required this.verticalShock,
    required this.harshBraking,
    required this.vibrationVariance,
    required this.avoidanceLateral,
    required this.minSpeedForAvoidance,
    required this.uploadCooldownSeconds,
  });

  final double verticalShock;
  final double harshBraking;
  final double vibrationVariance;
  final double avoidanceLateral;
  final double minSpeedForAvoidance;
  final int uploadCooldownSeconds;

  static const defaults = SensorThresholds(
    verticalShock: 4.0,
    harshBraking: 5.5,
    vibrationVariance: 2.5,
    avoidanceLateral: 4.5,
    minSpeedForAvoidance: 3.0,
    uploadCooldownSeconds: 60,
  );
}
