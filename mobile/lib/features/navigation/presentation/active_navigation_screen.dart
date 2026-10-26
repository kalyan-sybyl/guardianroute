import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/core/services/location_service.dart';
import 'package:guardianroute/features/map/presentation/guardian_map_widget.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_providers.dart';
import 'package:guardianroute/features/navigation/presentation/navigation_session_providers.dart';
import 'package:guardianroute/features/navigation/presentation/hazard_warning_banner.dart';

class ActiveNavigationScreen extends ConsumerStatefulWidget {
  const ActiveNavigationScreen({super.key});

  @override
  ConsumerState<ActiveNavigationScreen> createState() =>
      _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState
    extends ConsumerState<ActiveNavigationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final route = ref.read(selectedRouteProvider);
    if (route == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a route first.')),
        );
        context.pop();
      }
      return;
    }

    try {
      await ref.read(locationServiceProvider).ensurePermission();
      ref.invalidate(userPositionProvider);
      await ref.read(navigationSessionProvider.notifier).start();
    } on LocationPermissionDenied catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        context.pop();
      }
    }
  }

  Future<void> _endNavigation() async {
    await ref.read(navigationSessionProvider.notifier).stop();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(selectedRouteProvider);
    final session = ref.watch(navigationSessionProvider);
    final theme = Theme.of(context);

    if (route == null) {
      return const Scaffold(
        body: Center(child: Text('No active route')),
      );
    }

    final remainingKm = (session.remainingMeters / 1000).toStringAsFixed(1);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(navigationSessionProvider.notifier).stop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: GuardianMapWidget()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _endNavigation,
                          icon: const Icon(Icons.close),
                          tooltip: 'End navigation',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route.destinationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.alert != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: HazardWarningBanner(alert: session.alert!),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surface.withValues(alpha: 0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (session.arrived)
                              Text(
                                'You have arrived',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else ...[
                              Text(
                                '${session.remainingMinutes} min · $remainingKm km',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${route.option.label.wireName} route · '
                                'Risk ${route.option.riskScore}/100',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _endNavigation,
                              child: Text(
                                session.arrived ? 'Done' : 'End navigation',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
