import { test } from "node:test";
import assert from "node:assert/strict";
import { computeRouteRiskScore } from "./routeRisk";

test("computeRouteRiskScore weights max and critical segments", () => {
  const score = computeRouteRiskScore([30, 40, 90, 35]);
  assert.ok(score > 50);
});

test("computeRouteRiskScore returns 0 for empty samples", () => {
  assert.equal(computeRouteRiskScore([]), 0);
});
