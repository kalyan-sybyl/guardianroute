enum HazardReportStatus {
  pending,
  analyzing,
  completed,
  failed;

  static HazardReportStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return HazardReportStatus.pending;
      case 'ANALYZING':
        return HazardReportStatus.analyzing;
      case 'COMPLETED':
        return HazardReportStatus.completed;
      case 'FAILED':
        return HazardReportStatus.failed;
      default:
        return HazardReportStatus.pending;
    }
  }
}

class HazardAnalysisResult {
  const HazardAnalysisResult({
    required this.hazardType,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.recommendedAction,
  });

  final String hazardType;
  final String severity;
  final double confidence;
  final String description;
  final String recommendedAction;

  factory HazardAnalysisResult.fromMap(Map<String, dynamic> map) {
    return HazardAnalysisResult(
      hazardType: map['hazardType'] as String? ?? 'OTHER',
      severity: map['severity'] as String? ?? 'MODERATE',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      description: map['description'] as String? ?? '',
      recommendedAction: map['recommendedAction'] as String? ?? '',
    );
  }
}

class HazardReport {
  const HazardReport({
    required this.id,
    required this.status,
    required this.hazardId,
    required this.analysis,
    required this.error,
  });

  final String id;
  final HazardReportStatus status;
  final String? hazardId;
  final HazardAnalysisResult? analysis;
  final String? error;

  factory HazardReport.fromFirestore(String id, Map<String, dynamic> data) {
    final analysisRaw = data['analysis'];
    return HazardReport(
      id: id,
      status: HazardReportStatus.fromString(data['status'] as String?),
      hazardId: data['hazardId'] as String?,
      analysis: analysisRaw is Map<String, dynamic>
          ? HazardAnalysisResult.fromMap(analysisRaw)
          : null,
      error: data['error'] as String?,
    );
  }
}
