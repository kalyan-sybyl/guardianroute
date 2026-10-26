export type RiskLevel = "LOW" | "MODERATE" | "HIGH" | "CRITICAL";

export function riskLevelFromScore(score: number): RiskLevel {
  if (score <= 25) return "LOW";
  if (score <= 50) return "MODERATE";
  if (score <= 75) return "HIGH";
  return "CRITICAL";
}

export function severityToFactor(severity: string): number {
  switch (severity?.toUpperCase()) {
    case "LOW":
      return 0.25;
    case "MODERATE":
      return 0.5;
    case "HIGH":
      return 0.75;
    case "CRITICAL":
      return 1.0;
    default:
      return 0.4;
  }
}
