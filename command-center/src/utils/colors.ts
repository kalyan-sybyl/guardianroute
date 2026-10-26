export function severityColor(severity: string): string {
  switch (severity.toUpperCase()) {
    case "CRITICAL":
      return "#c62828";
    case "HIGH":
      return "#e65100";
    case "LOW":
      return "#2e7d32";
    default:
      return "#f9a825";
  }
}

export function riskScoreColor(score: number): string {
  if (score >= 76) return "#c62828";
  if (score >= 50) return "#e65100";
  if (score >= 26) return "#f9a825";
  return "#2e7d32";
}
