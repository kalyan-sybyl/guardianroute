import 'package:flutter/material.dart';
import 'package:guardianroute/features/guardian_pulse/domain/guardian_pulse_event.dart';

Future<void> showPulseDetailSheet(
  BuildContext context,
  GuardianPulseEvent pulse,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _PulseDetailBody(pulse: pulse),
  );
}

class _PulseDetailBody extends StatelessWidget {
  const _PulseDetailBody({required this.pulse});

  final GuardianPulseEvent pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.sensors, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Guardian Pulse™',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (pulse.isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'DEMO DATA',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('${pulse.status.label} road activity'),
          const SizedBox(height: 8),
          Text('${pulse.eventCount} sensor events in this area'),
          Text('Dominant: ${pulse.dominantEventType.replaceAll('_', ' ')}'),
          Text('${(pulse.confidence * 100).round()}% confidence'),
          if (pulse.hazardId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Linked to reported hazard',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Unusual rider sensor patterns may indicate an emerging hazard '
            'before it is reported.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
