import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/navigation/data/polyline_decoder.dart';
import 'package:guardianroute/features/navigation/data/route_plan_repository.dart';
import 'package:guardianroute/features/navigation/domain/route_option.dart';

final routePlanRepositoryProvider = Provider<RoutePlanRepository>((ref) {
  return RoutePlanRepository();
});

class SelectedRouteNotifier extends Notifier<SelectedRoute?> {
  @override
  SelectedRoute? build() => null;

  void set(SelectedRoute? route) => state = route;

  void clear() => state = null;
}

final selectedRouteProvider =
    NotifierProvider<SelectedRouteNotifier, SelectedRoute?>(
  SelectedRouteNotifier.new,
);

final routePolylinesProvider = Provider<Set<Polyline>>((ref) {
  final selected = ref.watch(selectedRouteProvider);
  if (selected == null || selected.polylinePoints.isEmpty) {
    return const {};
  }

  return {
    Polyline(
      polylineId: const PolylineId('active-route'),
      points: selected.polylinePoints,
      color: const Color(0xFF0D7377),
      width: 6,
    ),
  };
});

void selectRouteOption(
  WidgetRef ref, {
  required RouteOption option,
  required String destinationLabel,
}) {
  ref.read(selectedRouteProvider.notifier).set(
        SelectedRoute(
          option: option,
          polylinePoints: decodePolyline(option.encodedPolyline),
          destinationLabel: destinationLabel,
        ),
      );
}
