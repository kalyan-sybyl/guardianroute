import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/config/app_flavor.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/core/services/location_service.dart';
import 'package:guardianroute/features/map/data/demo_hazards.dart';
import 'package:guardianroute/features/map/data/hazard_repository.dart';
import 'package:guardianroute/features/map/data/places_autocomplete_service.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';
import 'package:guardianroute/features/map/domain/map_destination.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/guardian_pulse_providers.dart';
import 'package:guardianroute/features/map/presentation/hazard_marker_utils.dart';
import 'package:guardianroute/features/route_safety/presentation/risk_level_utils.dart';
import 'package:guardianroute/features/route_safety/presentation/road_risk_providers.dart';
import 'package:flutter/material.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final hazardRepositoryProvider = Provider<HazardRepository>((ref) {
  return HazardRepository();
});

final placesAutocompleteServiceProvider = Provider<PlacesAutocompleteService>((ref) {
  return PlacesAutocompleteService();
});

final hazardsStreamProvider = StreamProvider<List<Hazard>>((ref) {
  return ref.watch(hazardRepositoryProvider).watchActiveHazards();
});

final mapHazardsProvider = Provider<AsyncValue<List<Hazard>>>((ref) {
  final config = ref.watch(appConfigProvider);
  final live = ref.watch(hazardsStreamProvider);

  List<Hazard> withDemoFallback(List<Hazard> hazards) {
    final useDemoOverlay = config.flavor == AppFlavor.demo ||
        config.flavor == AppFlavor.development;
    if (!useDemoOverlay || hazards.isNotEmpty) {
      return hazards;
    }
    return kampalaDemoHazards();
  }

  return live.when(
    data: (hazards) => AsyncData(withDemoFallback(hazards)),
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) {
      if (config.flavor == AppFlavor.development ||
          config.flavor == AppFlavor.demo) {
        return AsyncData(kampalaDemoHazards());
      }
      return AsyncError(error, stackTrace);
    },
  );
});

class SelectedDestinationNotifier extends Notifier<MapDestination?> {
  @override
  MapDestination? build() => null;

  void set(MapDestination? destination) => state = destination;

  void clear() => state = null;
}

final selectedDestinationProvider =
    NotifierProvider<SelectedDestinationNotifier, MapDestination?>(
  SelectedDestinationNotifier.new,
);

class SelectedHazardNotifier extends Notifier<Hazard?> {
  @override
  Hazard? build() => null;

  void set(Hazard? hazard) => state = hazard;

  void clear() => state = null;
}

final selectedHazardProvider =
    NotifierProvider<SelectedHazardNotifier, Hazard?>(SelectedHazardNotifier.new);

class MapCameraNotifier extends Notifier<CameraPosition> {
  @override
  CameraPosition build() {
    return const CameraPosition(
      target: MapConstants.kampalaCenter,
      zoom: MapConstants.defaultZoom,
    );
  }

  void moveTo(LatLng target, {double? zoom}) {
    state = CameraPosition(
      target: target,
      zoom: zoom ?? state.zoom,
    );
  }
}

final mapCameraProvider =
    NotifierProvider<MapCameraNotifier, CameraPosition>(MapCameraNotifier.new);

/// Holds the live map controller after [GoogleMap.onMapCreated].
class MapControllerHolder extends Notifier<GoogleMapController?> {
  @override
  GoogleMapController? build() => null;

  void attach(GoogleMapController controller) => state = controller;

  Future<void> animateTo(LatLng target, {double? zoom}) async {
    final controller = state;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom ?? MapConstants.userLocationZoom,
        ),
      ),
    );
  }
}

final mapControllerHolderProvider =
    NotifierProvider<MapControllerHolder, GoogleMapController?>(
  MapControllerHolder.new,
);

final userPositionProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationTracker(service).track();
});

final mapMarkersProvider = Provider<Set<Marker>>((ref) {
  final hazards = ref.watch(mapHazardsProvider).value ?? [];
  final destination = ref.watch(selectedDestinationProvider);

  final markers = <Marker>{};

  for (final hazard in hazards) {
    markers.add(
      hazardToMarker(
        hazard,
        onTap: (h) => ref.read(selectedHazardProvider.notifier).set(h),
      ),
    );
  }

  if (destination != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Destination', snippet: destination.label),
      ),
    );
  }

  final pulses = ref.watch(mapGuardianPulsesProvider).value ?? [];
  for (final pulse in pulses) {
    markers.add(
      Marker(
        markerId: MarkerId('pulse-${pulse.id}'),
        position: pulse.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'Guardian Pulse™',
          snippet:
              '${pulse.eventCount} events · ${(pulse.confidence * 100).round()}%',
        ),
        onTap: () => ref.read(selectedPulseProvider.notifier).set(pulse),
      ),
    );
  }

  return markers;
});

final mapPulseCirclesProvider = Provider<Set<Circle>>((ref) {
  final pulses = ref.watch(mapGuardianPulsesProvider).value ?? [];
  return pulses
      .map(
        (pulse) => Circle(
          circleId: CircleId('pulse-circle-${pulse.id}'),
          center: pulse.location,
          radius: pulse.radiusMeters,
          fillColor: Colors.deepPurple.withValues(alpha: 0.18),
          strokeColor: Colors.deepPurple,
          strokeWidth: 2,
        ),
      )
      .toSet();
});

final mapRiskCirclesProvider = Provider<Set<Circle>>((ref) {
  if (!ref.watch(riskOverlayEnabledProvider)) {
    return const {};
  }
  final segments = ref.watch(mapRoadSegmentsProvider).value ?? [];
  return segments
      .map(
        (segment) {
          final color = riskScoreColor(segment.riskScore);
          return Circle(
            circleId: CircleId('risk-${segment.id}'),
            center: segment.location,
            radius: riskCircleRadiusMeters(segment.riskLevel),
            fillColor: color.withValues(alpha: 0.22),
            strokeColor: color.withValues(alpha: 0.85),
            strokeWidth: 2,
            zIndex: 1,
          );
        },
      )
      .toSet();
});

final mapOverlayCirclesProvider = Provider<Set<Circle>>((ref) {
  return {
    ...ref.watch(mapRiskCirclesProvider),
    ...ref.watch(mapPulseCirclesProvider),
  };
});
