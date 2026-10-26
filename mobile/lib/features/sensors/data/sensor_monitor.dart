import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:guardianroute/features/sensors/data/sensor_event_classifier.dart';
import 'package:guardianroute/features/sensors/data/sensor_event_repository.dart';
import 'package:guardianroute/features/sensors/domain/sensor_event_type.dart';
import 'package:guardianroute/features/sensors/domain/sensor_thresholds.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef PositionProvider = Future<Position?> Function();

class SensorMonitor {
  SensorMonitor({
    required SensorThresholds thresholds,
    required this._repository,
    required this._anonymousDeviceId,
    required this._positionProvider,
  })  : _classifier = SensorEventClassifier(thresholds),
        _cooldownSeconds = thresholds.uploadCooldownSeconds;

  final SensorEventClassifier _classifier;
  final SensorEventRepository _repository;
  final String _anonymousDeviceId;
  final PositionProvider _positionProvider;
  final int _cooldownSeconds;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _speedTimer;
  Position? _lastPosition;

  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    _accelSub = userAccelerometerEventStream().listen(_onAccel);
    _gyroSub = gyroscopeEventStream().listen(_onGyro);
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollSpeed());
  }

  Future<void> stop() async {
    _running = false;
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    _speedTimer?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _speedTimer = null;
  }

  void _onAccel(UserAccelerometerEvent event) {
    final detected = _classifier.ingestUserAccel(event);
    _emit(detected);
  }

  void _onGyro(GyroscopeEvent event) {
    final detected = _classifier.ingestGyro(event);
    _emit(detected);
  }

  Future<void> _pollSpeed() async {
    try {
      final position = await _positionProvider();
      if (position == null) return;
      _lastPosition = position;
      final detected = _classifier.ingestSpeed(
        position.speed >= 0 ? position.speed : null,
      );
      _emit(detected);
    } catch (e) {
      appLogger.w('Speed poll failed: $e');
    }
  }

  Future<void> _emit(List<DetectedSensorEvent> events) async {
    if (events.isEmpty) return;

    Position? position = _lastPosition;
    position ??= await _positionProvider();
    if (position == null) return;

    for (final event in events) {
      if (event.type == SensorEventType.suddenAvoidance &&
          !_classifier.shouldAllowAvoidance(
            position.speed >= 0 ? position.speed : null,
          )) {
        continue;
      }

      await _repository.submit(
        anonymousDeviceId: _anonymousDeviceId,
        event: event,
        position: position,
        cooldownSeconds: _cooldownSeconds,
      );
    }
  }
}
