import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardianroute/core/services/location_service.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';
import 'package:guardianroute/features/navigation/domain/route_option.dart'
    show RouteLabel, RouteOption, RoutePlanResult;
import 'package:guardianroute/features/navigation/presentation/navigation_providers.dart';
import 'package:guardianroute/features/route_safety/presentation/risk_level_utils.dart';

class RouteComparisonScreen extends ConsumerStatefulWidget {
  const RouteComparisonScreen({super.key});

  @override
  ConsumerState<RouteComparisonScreen> createState() =>
      _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends ConsumerState<RouteComparisonScreen> {
  RoutePlanResult? _plan;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoutes());
  }

  Future<void> _loadRoutes() async {
    final destination = ref.read(selectedDestinationProvider);
    if (destination == null) {
      setState(() {
        _loading = false;
        _error = 'Choose a destination on the map first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      final origin = LatLng(position.latitude, position.longitude);
      final repo = ref.read(routePlanRepositoryProvider);
      final plan = await repo.planSafeRoutes(
        origin: origin,
        destination: destination.location,
      );
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } on LocationPermissionDenied catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectRoute(RouteOption option) async {
    final destination = ref.read(selectedDestinationProvider);
    if (destination == null) return;

    selectRouteOption(
      ref,
      option: option,
      destinationLabel: destination.label,
    );

    final isSafest = option.label == RouteLabel.safest;
    await FirebaseAnalytics.instance.logEvent(
      name: 'route_selected',
      parameters: {
        'label': option.label.wireName,
        'risk_score': option.riskScore,
      },
    );
    if (isSafest) {
      await FirebaseAnalytics.instance.logEvent(name: 'safest_route_selected');
    }

    if (!mounted) return;
    context.pop();
    context.push('/map/navigate');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = ref.watch(selectedDestinationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose route'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (destination != null)
                      Text(
                        destination.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    if (_plan?.isDemo == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          'DEMO ROUTES — illustrative risk scores',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_plan != null) ...[
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _plan!.recommendationMessage,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._plan!.routes.map(
                        (route) => _RouteCard(
                          route: route,
                          recommended: route.label == _plan!.recommendedLabel,
                          onSelect: () => _selectRoute(route),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.recommended,
    required this.onSelect,
  });

  final RouteOption route;
  final bool recommended;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = riskScoreColor(route.riskScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  route.label.wireName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recommended) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Recommended'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text('${route.durationMinutes} min · ${route.distanceKm} km'),
            const SizedBox(height: 4),
            Text(
              'Risk ${route.riskScore}/100',
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              route.summary,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onSelect,
              child: const Text('Use this route'),
            ),
          ],
        ),
      ),
    );
  }
}
