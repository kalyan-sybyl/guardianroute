import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/constants/map_constants.dart';
import 'package:guardianroute/core/providers/app_providers.dart';
import 'package:guardianroute/core/services/location_service.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';
import 'package:guardianroute/features/map/presentation/destination_search_sheet.dart';
import 'package:guardianroute/features/map/presentation/guardian_map_widget.dart';
import 'package:guardianroute/features/guardian_pulse/domain/guardian_pulse_event.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/guardian_pulse_providers.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/pulse_detail_sheet.dart';
import 'package:guardianroute/features/map/presentation/hazard_detail_sheet.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_providers.dart';
import 'package:guardianroute/features/sensors/presentation/sensor_providers.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
      ref.read(sensorMonitorControllerProvider.notifier).setMapActive(true);
    });
  }

  @override
  void dispose() {
    ref.read(sensorMonitorControllerProvider.notifier).setMapActive(false);
    super.dispose();
  }

  Future<void> _initLocation() async {
    final service = ref.read(locationServiceProvider);
    try {
      await service.ensurePermission();
      ref.invalidate(userPositionProvider);
    } on LocationPermissionDenied catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _recenterOnUser() async {
    final service = ref.read(locationServiceProvider);
    try {
      final position = await service.getCurrentPosition();
      await ref.read(mapControllerHolderProvider.notifier).animateTo(
            LatLng(position.latitude, position.longitude),
            zoom: MapConstants.userLocationZoom,
          );
    } on LocationPermissionDenied catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final destination = ref.watch(selectedDestinationProvider);
    final hazardsAsync = ref.watch(mapHazardsProvider);
    final sensorState = ref.watch(sensorMonitorControllerProvider);
    final sensorsEnabled = ref.watch(sensorContributionEnabledProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);

    ref.listen<Hazard?>(selectedHazardProvider, (previous, next) {
      if (next != null && mounted) {
        showHazardDetailSheet(context, next).whenComplete(() {
          ref.read(selectedHazardProvider.notifier).clear();
        });
      }
    });

    ref.listen<GuardianPulseEvent?>(selectedPulseProvider, (previous, next) {
      if (next != null && mounted) {
        showPulseDetailSheet(context, next).whenComplete(() {
          ref.read(selectedPulseProvider.notifier).clear();
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('GuardianRoute'),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        bottom: sensorsEnabled && sensorState.monitoring
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Road Guardian sensors active',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => context.push('/safety'),
            icon: const Icon(Icons.sensors),
            tooltip: 'Guardian Pulse',
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GuardianMapWidget()),
          if (hazardsAsync.isLoading)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(child: LinearProgressIndicator()),
            ),
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'locate',
              onPressed: _recenterOnUser,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => showDestinationSearchSheet(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              destination?.label ?? 'Where are you going?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedRoute != null)
                  FilledButton(
                    onPressed: () => context.push('/map/navigate'),
                    child: const Text('Start navigation'),
                  ),
                if (selectedRoute != null) const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: destination == null
                      ? null
                      : () => context.push('/map/routes'),
                  child: Text(
                    selectedRoute == null ? 'Plan route' : 'Change route',
                  ),
                ),
                if (selectedRoute != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${selectedRoute.option.label.wireName} · '
                      'Risk ${selectedRoute.option.riskScore}/100',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (config.flavor.name == 'demo')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Demo hazards shown when Firestore is empty.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map/report'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report'),
      ),
    );
  }
}
