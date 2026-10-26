import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/features/sensors/data/anonymous_device_id.dart';
import 'package:guardianroute/features/sensors/data/sensor_event_repository.dart';
import 'package:guardianroute/features/sensors/data/sensor_monitor.dart';
import 'package:guardianroute/features/sensors/domain/sensor_thresholds.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';

const _sensorContributionKey = 'sensor_contribution_enabled';

final sensorEventRepositoryProvider = Provider<SensorEventRepository>((ref) {
  return SensorEventRepository();
});

final sensorThresholdsProvider = Provider<SensorThresholds>((ref) {
  final rc = FirebaseRemoteConfig.instance;
  return SensorThresholds(
    verticalShock: rc.getDouble('vertical_shock_threshold'),
    harshBraking: rc.getDouble('harsh_braking_threshold'),
    vibrationVariance: rc.getDouble('vibration_variance_threshold'),
    avoidanceLateral: rc.getDouble('avoidance_lateral_threshold'),
    minSpeedForAvoidance: rc.getDouble('sensor_min_speed_avoidance'),
    uploadCooldownSeconds: rc.getInt('sensor_upload_cooldown_seconds'),
  );
});

final sensorContributionEnabledProvider =
    NotifierProvider<SensorContributionNotifier, bool>(
  SensorContributionNotifier.new,
);

class SensorContributionNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_sensorContributionKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_sensorContributionKey, value);
    state = value;
    ref.read(sensorMonitorControllerProvider.notifier).refresh();
  }
}

final anonymousDeviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return getOrCreateAnonymousDeviceId(prefs);
});

final sensorMonitorControllerProvider =
    NotifierProvider<SensorMonitorController, SensorMonitorState>(
  SensorMonitorController.new,
);

class SensorMonitorState {
  const SensorMonitorState({
    this.mapActive = false,
    this.monitoring = false,
  });

  final bool mapActive;
  final bool monitoring;
}

class SensorMonitorController extends Notifier<SensorMonitorState> {
  SensorMonitor? _monitor;

  @override
  SensorMonitorState build() {
    ref.onDispose(() {
      _monitor?.stop();
    });
    return const SensorMonitorState();
  }

  void setMapActive(bool active) {
    state = SensorMonitorState(mapActive: active, monitoring: state.monitoring);
    refresh();
  }

  Future<void> refresh() async {
    final enabled = ref.read(sensorContributionEnabledProvider);
    final shouldRun = enabled && state.mapActive;

    if (!shouldRun) {
      await _monitor?.stop();
      _monitor = null;
      state = SensorMonitorState(mapActive: state.mapActive, monitoring: false);
      return;
    }

    if (_monitor != null) {
      state = SensorMonitorState(mapActive: state.mapActive, monitoring: true);
      return;
    }

    final deviceId = await ref.read(anonymousDeviceIdProvider.future);
    final thresholds = ref.read(sensorThresholdsProvider);
    final repository = ref.read(sensorEventRepositoryProvider);
    final locationService = ref.read(locationServiceProvider);

    _monitor = SensorMonitor(
      thresholds: thresholds,
      repository: repository,
      anonymousDeviceId: deviceId,
      positionProvider: () async {
        try {
          return await locationService.getCurrentPosition();
        } catch (_) {
          return null;
        }
      },
    );

    await _monitor!.start();
    state = SensorMonitorState(mapActive: state.mapActive, monitoring: true);
  }
}
