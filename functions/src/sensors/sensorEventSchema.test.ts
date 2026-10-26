import { test } from "node:test";
import assert from "node:assert/strict";
import { submitSensorEventSchema } from "./sensorEventSchema";

test("submitSensorEventSchema accepts valid event", () => {
  const result = submitSensorEventSchema.parse({
    anonymousDeviceId: "device-abc-123",
    eventType: "VERTICAL_SHOCK",
    latitude: 0.3476,
    longitude: 32.5825,
    magnitude: 4.2,
    speed: 8.5,
    heading: 110,
  });
  assert.equal(result.eventType, "VERTICAL_SHOCK");
});
