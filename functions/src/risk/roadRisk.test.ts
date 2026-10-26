import { test } from "node:test";
import assert from "node:assert/strict";
import { computeRoadRisk } from "./roadRisk";
import { DEFAULT_RISK_WEIGHTS } from "./riskWeights";

test("computeRoadRisk returns elevated score for hazard-heavy cell", () => {
  const result = computeRoadRisk(
    {
      hazardSeverity: 0.95,
      harshBraking: 0.6,
      sensorAnomalies: 0.5,
      verifiedReports: 0.7,
      environmental: 0.4,
      timeOfDay: 0.3,
      historical: 0.2,
    },
    DEFAULT_RISK_WEIGHTS,
  );
  assert.ok(result.riskScore >= 55);
  assert.equal(result.riskLevel, "HIGH");
});

test("computeRoadRisk clamps to 0-100", () => {
  const result = computeRoadRisk(
    {
      hazardSeverity: 1,
      harshBraking: 1,
      sensorAnomalies: 1,
      verifiedReports: 1,
      environmental: 1,
      timeOfDay: 1,
      historical: 1,
    },
    DEFAULT_RISK_WEIGHTS,
  );
  assert.equal(result.riskScore, 100);
});
