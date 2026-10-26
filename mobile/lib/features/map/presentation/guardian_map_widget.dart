import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_providers.dart';

class GuardianMapWidget extends ConsumerStatefulWidget {
  const GuardianMapWidget({super.key});

  @override
  ConsumerState<GuardianMapWidget> createState() => _GuardianMapWidgetState();
}

class _GuardianMapWidgetState extends ConsumerState<GuardianMapWidget> {
  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(mapCameraProvider);
    final markers = ref.watch(mapMarkersProvider);
    final circles = ref.watch(mapOverlayCirclesProvider);
    final polylines = ref.watch(routePolylinesProvider);
    final positionAsync = ref.watch(userPositionProvider);

    final myLocationEnabled = positionAsync.hasValue;

    return GoogleMap(
      initialCameraPosition: camera,
      markers: markers,
      circles: circles,
      polylines: polylines,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        ref.read(mapControllerHolderProvider.notifier).attach(controller);
      },
      onCameraMove: (position) {
        ref.read(mapCameraProvider.notifier).moveTo(
              position.target,
              zoom: position.zoom,
            );
      },
    );
  }
}
