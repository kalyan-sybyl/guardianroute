import { RiskWeights } from "./riskWeights";
import { riskLevelFromScore } from "./riskLevels";

export interface RoadRiskComponents {
  hazardSeverity: number;
  harshBraking: number;
  sensorAnomalies: number;
  verifiedReports: number;
  environmental: number;
  timeOfDay: number;
  historical: number;
}

export interface RoadRiskResult {
  riskScore: number;
  riskLevel: ReturnType<typeof riskLevelFromScore>;
  components: RoadRiskComponents;
}

export function computeRoadRisk(
  components: RoadRiskComponents,
  weights: RiskWeights,
): RoadRiskResult {
  const weighted =
    components.hazardSeverity * weights.hazard +
    components.harshBraking * weights.harshBraking +
    components.sensorAnomalies * weights.sensorAnomalies +
    components.verifiedReports * weights.verifiedReports +
    components.environmental * weights.environmental +
    components.timeOfDay * weights.timeOfDay +
    components.historical * weights.historical;

  const riskScore = Math.round(Math.min(100, Math.max(0, weighted * 100)));
  return {
    riskScore,
    riskLevel: riskLevelFromScore(riskScore),
    components,
  };
}

export function normalizeCount(count: number, cap: number): number {
  if (cap <= 0) return 0;
  return Math.min(1, count / cap);
}
