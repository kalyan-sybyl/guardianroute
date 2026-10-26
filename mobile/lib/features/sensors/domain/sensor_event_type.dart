enum SensorEventType {
  harshBraking,
  verticalShock,
  abnormalVibration,
  suddenAvoidance;

  String get wireName {
    switch (this) {
      case SensorEventType.harshBraking:
        return 'HARSH_BRAKING';
      case SensorEventType.verticalShock:
        return 'VERTICAL_SHOCK';
      case SensorEventType.abnormalVibration:
        return 'ABNORMAL_VIBRATION';
      case SensorEventType.suddenAvoidance:
        return 'SUDDEN_AVOIDANCE';
    }
  }
}

class DetectedSensorEvent {
  const DetectedSensorEvent({
    required this.type,
    required this.magnitude,
    required this.occurredAt,
  });

  final SensorEventType type;
  final double magnitude;
  final DateTime occurredAt;
}
