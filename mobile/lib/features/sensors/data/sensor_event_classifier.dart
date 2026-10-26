import 'dart:math';

import 'package:guardianroute/features/sensors/domain/sensor_event_type.dart';
import 'package:guardianroute/features/sensors/domain/sensor_thresholds.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Stateful classifier — one instance per active monitoring session.
class SensorEventClassifier {
  SensorEventClassifier(this.thresholds);

  final SensorThresholds thresholds;

  final List<double> _gyroMagnitudes = [];
  static const _gyroWindow = 25;

  double? _prevSpeedMps;
  DateTime? _prevSpeedAt;

  List<DetectedSensorEvent> ingestUserAccel(UserAccelerometerEvent event) {
    final events = <DetectedSensorEvent>[];
    final now = DateTime.now();
    final x = event.x;
    final y = event.y;
    final z = event.z;

    if (z.abs() >= thresholds.verticalShock) {
      events.add(
        DetectedSensorEvent(
          type: SensorEventType.verticalShock,
          magnitude: z.abs(),
          occurredAt: now,
        ),
      );
    }

    if (y <= -thresholds.harshBraking) {
      events.add(
        DetectedSensorEvent(
          type: SensorEventType.harshBraking,
          magnitude: y.abs(),
          occurredAt: now,
        ),
      );
    }

    if (x.abs() >= thresholds.avoidanceLateral) {
      events.add(
        DetectedSensorEvent(
          type: SensorEventType.suddenAvoidance,
          magnitude: x.abs(),
          occurredAt: now,
        ),
      );
    }

    return events;
  }

  List<DetectedSensorEvent> ingestGyro(GyroscopeEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    _gyroMagnitudes.add(magnitude);
    if (_gyroMagnitudes.length > _gyroWindow) {
      _gyroMagnitudes.removeAt(0);
    }

    if (_gyroMagnitudes.length < _gyroWindow) {
      return const [];
    }

    final mean = _gyroMagnitudes.reduce((a, b) => a + b) / _gyroMagnitudes.length;
    final variance = _gyroMagnitudes
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        _gyroMagnitudes.length;

    if (variance >= thresholds.vibrationVariance) {
      return [
        DetectedSensorEvent(
          type: SensorEventType.abnormalVibration,
          magnitude: sqrt(variance),
          occurredAt: DateTime.now(),
        ),
      ];
    }

    return const [];
  }

  List<DetectedSensorEvent> ingestSpeed(double? speedMps) {
    if (speedMps == null) return const [];
    final now = DateTime.now();
    final prev = _prevSpeedMps;
    final prevAt = _prevSpeedAt;
    _prevSpeedMps = speedMps;
    _prevSpeedAt = now;

    if (prev == null || prevAt == null) return const [];
    final dt = now.difference(prevAt).inMilliseconds / 1000.0;
    if (dt <= 0 || dt > 3) return const [];

    final decel = (prev - speedMps) / dt;
    if (decel >= thresholds.harshBraking && speedMps < prev) {
      return [
        DetectedSensorEvent(
          type: SensorEventType.harshBraking,
          magnitude: decel,
          occurredAt: now,
        ),
      ];
    }

    return const [];
  }

  bool shouldAllowAvoidance(double? speedMps) {
    if (speedMps == null) return false;
    return speedMps >= thresholds.minSpeedForAvoidance;
  }
}
