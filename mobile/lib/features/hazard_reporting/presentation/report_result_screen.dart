import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardianroute/app/theme.dart';
import 'package:guardianroute/features/hazard_reporting/domain/hazard_report.dart';
import 'package:guardianroute/features/hazard_reporting/presentation/hazard_report_providers.dart';

class ReportResultScreen extends ConsumerWidget {
  const ReportResultScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(hazardReportStreamProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: reportAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Gemini is analyzing your report…'),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (report) => _ReportResultBody(report: report),
      ),
    );
  }
}

class _ReportResultBody extends StatelessWidget {
  const _ReportResultBody({required this.report});

  final HazardReport report;

  Color _severityColor(BuildContext context, String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return GuardianColors.safetyGreen;
      case 'MODERATE':
        return GuardianColors.warmAmber;
      case 'HIGH':
        return Colors.deepOrange;
      case 'CRITICAL':
        return GuardianColors.alertRed;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (report.status == HazardReportStatus.failed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Analysis failed', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(report.error ?? 'Unknown error'),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/map'),
              child: const Text('Back to map'),
            ),
          ],
        ),
      );
    }

    if (report.status != HazardReportStatus.completed || report.analysis == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing hazard…'),
          ],
        ),
      );
    }

    final analysis = report.analysis!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hazard detected',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            analysis.hazardType.replaceAll('_', ' '),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${analysis.severity} RISK',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _severityColor(context, analysis.severity),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(analysis.confidence * 100).round()}% confidence',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(analysis.description, textAlign: TextAlign.center),
          if (analysis.recommendedAction.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              analysis.recommendedAction,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const Spacer(),
          FilledButton(
            onPressed: () => context.go('/map'),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
