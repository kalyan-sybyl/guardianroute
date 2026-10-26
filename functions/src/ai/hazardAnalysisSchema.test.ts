import { test } from "node:test";
import assert from "node:assert/strict";
import { parseHazardAnalysis } from "./hazardAnalysisSchema";

test("parseHazardAnalysis accepts valid payload", () => {
  const result = parseHazardAnalysis({
    hazardType: "POTHOLE",
    severity: "HIGH",
    confidence: 0.94,
    description: "Large pothole in travel lane.",
    recommendedAction: "Reduce speed.",
  });
  assert.equal(result.hazardType, "POTHOLE");
  assert.equal(result.severity, "HIGH");
});
