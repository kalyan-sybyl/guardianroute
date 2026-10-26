export function computeRouteRiskScore(sampleScores: number[]): number {
  if (sampleScores.length === 0) return 0;

  const avg =
    sampleScores.reduce((sum, value) => sum + value, 0) / sampleScores.length;
  const max = Math.max(...sampleScores);
  const criticalCount = sampleScores.filter((s) => s >= 76).length;
  const criticalPenalty = Math.min(1, criticalCount / 3);

  const normalized = avg * 0.6 + max * 0.25 + criticalPenalty * 0.15;
  return Math.round(Math.min(100, Math.max(0, normalized)));
}
