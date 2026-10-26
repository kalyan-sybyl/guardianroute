import 'package:flutter/material.dart';
import 'package:guardianroute/features/map/domain/hazard.dart';

Future<void> showHazardDetailSheet(BuildContext context, Hazard hazard) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _HazardDetailBody(hazard: hazard),
  );
}

class _HazardDetailBody extends StatelessWidget {
  const _HazardDetailBody({required this.hazard});

  final Hazard hazard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hazard.isDemo)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'DEMO DATA',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            hazard.publicId,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${hazard.type} · ${hazard.severity.label}'),
          const SizedBox(height: 8),
          Text(
            '${(hazard.confidence * 100).round()}% confidence',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(hazard.description),
          if (hazard.recommendedAction != null) ...[
            const SizedBox(height: 12),
            Text(
              hazard.recommendedAction!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
