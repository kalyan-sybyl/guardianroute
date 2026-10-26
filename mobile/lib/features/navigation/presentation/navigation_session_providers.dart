import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/core/services/navigation_voice_service.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';
import 'package:guardianroute/features/navigation/domain/hazard_proximity.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_providers.dart';

const _voiceWarningsKey = 'navigation_voice_warnings_enabled';

final navigationVoiceServiceProvider = Provider<NavigationVoiceService>((ref) {
  return NavigationVoiceService();
});

final navigationVoiceEnabledProvider =
    NotifierProvider<NavigationVoiceEnabledNotifier, bool>(
  NavigationVoiceEnabledNotifier.new,
);

class NavigationVoiceEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_voiceWarningsKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_voiceWarningsKey, value);
    state = value;
    if (!value) {
      await ref.read(navigationVoiceServiceProvider).stop();
    }
  }
}

class NavigationSessionState {
  const NavigationSessionState({
    this.active = false,
    this.alert,
    this.remainingMeters = 0,
    this.remainingMinutes = 0,
    this.arrived = false,
  });

  final bool active;
  final HazardProximityAlert? alert;
  final double remainingMeters;
  final int remainingMinutes;
  final bool arrived;

  NavigationSessionState copyWith({
    bool? active,
    HazardProximityAlert? alert,
    bool clearAlert = false,
    double? remainingMeters,
    int? remainingMinutes,
    bool? arrived,
  }) {
    return NavigationSessionState(
      active: active ?? this.active,
      alert: clearAlert ? null : (alert ?? this.alert),
      remainingMeters: remainingMeters ?? this.remainingMeters,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      arrived: arrived ?? this.arrived,
    );
  }
}

class NavigationSessionController extends Notifier<NavigationSessionState> {
  final Set<String> _warnedHazardIds = {};

  @override
  NavigationSessionState build() {
    ref.onDispose(() {
      ref.read(navigationVoiceServiceProvider).stop();
    });

    ref.listen(userPositionProvider, (previous, next) {
      if (!state.active) return;
      final position = next.value;
      if (position != null) {
        _onPosition(position);
      }
    });

    ref.listen(mapHazardsProvider, (previous, next) {
      if (!state.active) return;
      final position = ref.read(userPositionProvider).value;
      if (position != null) {
        _onPosition(position);
      }
    });

    return const NavigationSessionState();
  }

  Future<void> start() async {
    final route = ref.read(selectedRouteProvider);
    if (route == null) return;

    _warnedHazardIds.clear();
    ref.read(navigationVoiceServiceProvider).resetCooldown();

    await FirebaseAnalytics.instance.logEvent(name: 'navigation_started');

    state = state.copyWith(active: true, arrived: false, clearAlert: true);

    final position = ref.read(userPositionProvider).value;
    if (position != null) {
      _onPosition(position);
    }
  }

  Future<void> stop() async {
    await ref.read(navigationVoiceServiceProvider).stop();
    _warnedHazardIds.clear();
    state = const NavigationSessionState();
  }

  void _onPosition(Position position) {
    final route = ref.read(selectedRouteProvider);
    if (route == null) {
      state = state.copyWith(active: false, clearAlert: true);
      return;
    }

    final user = LatLng(position.latitude, position.longitude);
    final polyline = route.polylinePoints;
    final hazards = ref.read(mapHazardsProvider).value ?? [];

    final warningMeters =
        FirebaseRemoteConfig.instance.getInt('hazard_warning_distance_meters');

    final alert = findNearestRouteHazard(
      user: user,
      routePolyline: polyline,
      hazards: hazards,
      warningDistanceMeters: warningMeters.toDouble(),
    );

    final remaining = remainingDistanceAlongPolylineMeters(user, polyline);
    final arrived = remaining < 40;

    final routeKm = route.option.distanceKm;
    final routeMin = route.option.durationMinutes;
    final etaMinutes = routeKm > 0
        ? ((remaining / 1000) / routeKm * routeMin).round().clamp(0, 999)
        : 0;

    state = state.copyWith(
      alert: alert,
      clearAlert: alert == null,
      remainingMeters: remaining,
      remainingMinutes: etaMinutes,
      arrived: arrived,
    );

    if (alert != null && !_warnedHazardIds.contains(alert.hazard.id)) {
      _warnedHazardIds.add(alert.hazard.id);
      FirebaseAnalytics.instance.logEvent(
        name: 'hazard_warning_displayed',
        parameters: {
          'severity': alert.hazard.severity.name,
          'distance_m': alert.distanceMeters,
        },
      );

      if (ref.read(navigationVoiceEnabledProvider)) {
        ref.read(navigationVoiceServiceProvider).speakHazardWarning(
              hazardKey: alert.hazard.id,
              typeLabel: alert.subtitle,
              distanceMeters: alert.distanceMeters,
            );
      }
    }

    ref.read(mapCameraProvider.notifier).moveTo(user);
    ref.read(mapControllerHolderProvider.notifier).animateTo(
          user,
          zoom: 17,
        );
  }
}

final navigationSessionProvider =
    NotifierProvider<NavigationSessionController, NavigationSessionState>(
  NavigationSessionController.new,
);
