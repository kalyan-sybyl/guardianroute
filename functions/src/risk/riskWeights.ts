export interface RiskWeights {
  hazard: number;
  harshBraking: number;
  sensorAnomalies: number;
  verifiedReports: number;
  environmental: number;
  timeOfDay: number;
  historical: number;
}

export const DEFAULT_RISK_WEIGHTS: RiskWeights = {
  hazard: 0.3,
  harshBraking: 0.2,
  sensorAnomalies: 0.15,
  verifiedReports: 0.15,
  environmental: 0.1,
  timeOfDay: 0.05,
  historical: 0.05,
};
