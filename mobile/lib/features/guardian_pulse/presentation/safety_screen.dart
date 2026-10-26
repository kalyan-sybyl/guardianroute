import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/guardian_pulse_providers.dart';
import 'package:guardianroute/features/guardian_pulse/presentation/pulse_detail_sheet.dart';
import 'package:guardianroute/features/route_safety/presentation/risk_level_utils.dart';
import 'package:guardianroute/features/route_safety/presentation/road_risk_providers.dart';

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulsesAsync = ref.watch(mapGuardianPulsesProvider);
    final segmentsAsync = ref.watch(mapRoadSegmentsProvider);
    final weights = ref.watch(riskWeightsSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Road risk intelligence',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Server-calculated segment scores (0–100) from hazards, sensors, '
            'and reports. Weights are tunable via Remote Config.',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show risk areas on map'),
            value: ref.watch(riskOverlayEnabledProvider),
            onChanged: (v) =>
                ref.read(riskOverlayEnabledProvider.notifier).setEnabled(v),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              try {
                final result = await runRoadRiskRecalculation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Risk engine: ${result['segmentsUpdated'] ?? 1} segment(s) updated',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Risk recalculation failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Recalculate road risk'),
          ),
          const SizedBox(height: 8),
          Text(
            'Weights (hazard ${weights['hazard']}, braking ${weights['harshBraking']}, '
            'sensors ${weights['sensorAnomalies']})',
            style: theme.textTheme.bodySmall,
          ),
          segmentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text('Risk data error: $e'),
            data: (segments) {
              if (segments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No elevated-risk segments yet.'),
                );
              }
              return Column(
                children: segments
                    .take(8)
                    .map(
                      (segment) => ListTile(
                        leading: Icon(
                          Icons.blur_circular,
                          color: riskScoreColor(segment.riskScore),
                        ),
                        title: Text('Risk ${segment.riskScore}/100'),
                        subtitle: Text(
                          '${segment.riskLevel.wireName} · ${segment.geohash}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          Text(
            'Guardian Pulse™',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live clusters of abnormal rider sensor activity that may '
            'signal emerging road hazards.',
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              try {
                final result = await runGuardianPulseScan();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Scan complete: ${result['eventsScanned']} events, '
                        '${result['pulsesCreated']} new pulses',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scan failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.radar),
            label: const Text('Run pulse scan now'),
          ),
          const SizedBox(height: 16),
          pulsesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Pulse error: $e'),
            data: (pulses) {
              if (pulses.isEmpty) {
                return const Text('No active Guardian Pulse zones right now.');
              }
              return Column(
                children: pulses
                    .map(
                      (pulse) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.waves),
                          title: Text(
                            '${pulse.dominantEventType.replaceAll('_', ' ')} cluster',
                          ),
                          subtitle: Text(
                            '${pulse.eventCount} events · '
                            '${(pulse.confidence * 100).round()}% confidence',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showPulseDetailSheet(context, pulse),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
