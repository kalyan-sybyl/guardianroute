import { test } from "node:test";
import assert from "node:assert/strict";
import {
  clusterSensorEvents,
  computePulseConfidence,
  shouldEmitPulse,
} from "./pulseClustering";

test("clusters events by geohash cell", () => {
  const clusters = clusterSensorEvents(
    [
      { geohash: "kxn00123", eventType: "VERTICAL_SHOCK" },
      { geohash: "kxn00124", eventType: "VERTICAL_SHOCK" },
      { geohash: "kyzzz200", eventType: "HARSH_BRAKING" },
    ],
    5,
  );
  assert.equal(clusters.length, 2);
  const main = clusters.find((c) => c.geohashCell === "kxn00");
  assert.ok(main);
  assert.equal(main!.eventCount, 2);
});

test("shouldEmitPulse when spike exceeds threshold", () => {
  const cluster = {
    geohashCell: "kxn00",
    eventCount: 20,
    dominantEventType: "VERTICAL_SHOCK",
    eventTypeCounts: { VERTICAL_SHOCK: 20 },
  };
  const ok = shouldEmitPulse(cluster, {
    windowMinutes: 30,
    minEvents: 15,
    baselinePerHour: 2,
    spikeFactor: 4,
    geohashPrecision: 7,
  });
  assert.equal(ok, true);
});

test("computePulseConfidence caps at 0.95", () => {
  assert.equal(computePulseConfidence(100, true), 0.95);
});
