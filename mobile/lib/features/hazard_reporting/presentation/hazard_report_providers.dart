import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/features/hazard_reporting/data/hazard_report_repository.dart';
import 'package:guardianroute/features/hazard_reporting/domain/hazard_report.dart';

final hazardReportRepositoryProvider = Provider<HazardReportRepository>((ref) {
  return HazardReportRepository();
});

final hazardReportStreamProvider =
    StreamProvider.family<HazardReport, String>((ref, reportId) {
  return ref.watch(hazardReportRepositoryProvider).watchReport(reportId);
});
