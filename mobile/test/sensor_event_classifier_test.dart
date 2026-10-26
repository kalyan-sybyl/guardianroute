import 'package:flutter_test/flutter_test.dart';
import 'package:guardianroute/features/sensors/data/sensor_event_classifier.dart';
import 'package:guardianroute/features/sensors/domain/sensor_event_type.dart';
import 'package:guardianroute/features/sensors/domain/sensor_thresholds.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  test('detects vertical shock from user accelerometer', () {
    final classifier = SensorEventClassifier(SensorThresholds.defaults);
    final events = classifier.ingestUserAccel(
      UserAccelerometerEvent(0, 0, 6.5, DateTime.now()),
    );
    expect(events.any((e) => e.type == SensorEventType.verticalShock), isTrue);
  });

  test('detects harsh braking from longitudinal accel', () {
    final classifier = SensorEventClassifier(SensorThresholds.defaults);
    final events = classifier.ingestUserAccel(
      UserAccelerometerEvent(0, -6.2, 0, DateTime.now()),
    );
    expect(events.any((e) => e.type == SensorEventType.harshBraking), isTrue);
  });
}
