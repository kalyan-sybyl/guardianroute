import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  GeoPoint,
  Timestamp,
  Firestore,
  getFirestore,
} from "firebase-admin/firestore";
import ngeohash from "ngeohash";
import { distanceMeters } from "../geo/distance";
import {
  submitSensorEventSchema,
  SubmitSensorEventInput,
} from "./sensorEventSchema";

const COOLDOWN_SECONDS = 60;
const HAZARD_PROXIMITY_METERS = 75;

export const processSensorEvent = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const parsed = submitSensorEventSchema.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", parsed.error.message);
    }

    const input: SubmitSensorEventInput = parsed.data;
    const db = getFirestore();

    await assertCooldown(db, input.anonymousDeviceId, input.eventType);

    const geohash = ngeohash.encode(input.latitude, input.longitude, 9);
    const eventRef = db.collection("sensorEvents").doc();

    await eventRef.set({
      anonymousDeviceId: input.anonymousDeviceId,
      eventType: input.eventType,
      location: new GeoPoint(input.latitude, input.longitude),
      geohash,
      magnitude: input.magnitude,
      speed: input.speed ?? null,
      heading: input.heading ?? null,
      clientTimestamp: input.clientTimestamp ?? null,
      timestamp: FieldValue.serverTimestamp(),
    });

    const correlated = await correlateWithHazards(db, input);

    const { recomputeRoadRiskAt } = await import("../risk/calculateRoadRisk");
    void recomputeRoadRiskAt(input.latitude, input.longitude).catch((err) =>
      logger.warn("Road risk recompute failed", err),
    );

    logger.info("Sensor event recorded", {
      eventId: eventRef.id,
      eventType: input.eventType,
      correlatedHazards: correlated,
    });

    return { ok: true, eventId: eventRef.id, correlatedHazards: correlated };
  },
);

async function assertCooldown(
  db: Firestore,
  deviceId: string,
  eventType: string,
): Promise<void> {
  const cutoff = Timestamp.fromDate(
    new Date(Date.now() - COOLDOWN_SECONDS * 1000),
  );
  const recent = await db
    .collection("sensorEvents")
    .where("anonymousDeviceId", "==", deviceId)
    .where("eventType", "==", eventType)
    .where("timestamp", ">", cutoff)
    .limit(1)
    .get();

  if (!recent.empty) {
    throw new HttpsError(
      "resource-exhausted",
      "Sensor event rate limit. Try again shortly.",
    );
  }
}

async function correlateWithHazards(
  db: Firestore,
  input: SubmitSensorEventInput,
): Promise<number> {
  const prefix = ngeohash.encode(input.latitude, input.longitude, 6);
  const snapshot = await db
    .collection("hazards")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(20)
    .get();

  let count = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const loc = data.location as GeoPoint;
    const dist = distanceMeters(
      input.latitude,
      input.longitude,
      loc.latitude,
      loc.longitude,
    );
    if (dist > HAZARD_PROXIMITY_METERS) continue;

    const confidence = (data.confidence as number) ?? 0.5;
    await doc.ref.update({
      sensorEvidenceCount: FieldValue.increment(1),
      confidence: Math.min(0.99, confidence + 0.02),
      lastVerifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    count += 1;
  }

  return count;
}
