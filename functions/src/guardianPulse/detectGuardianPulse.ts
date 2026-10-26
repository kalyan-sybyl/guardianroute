import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  Firestore,
  GeoPoint,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import ngeohash from "ngeohash";
import { distanceMeters } from "../geo/distance";
import {
  clusterSensorEvents,
  computePulseConfidence,
  PulseDetectionConfig,
  shouldEmitPulse,
} from "./pulseClustering";

const HAZARD_LINK_METERS = 75;
const DEFAULT_RADIUS_METERS = 40;

async function loadConfig(): Promise<PulseDetectionConfig> {
  return {
    windowMinutes: 30,
    minEvents: 15,
    baselinePerHour: 2,
    spikeFactor: 4,
    geohashPrecision: 7,
  };
}

export async function runGuardianPulseDetection(): Promise<{
  pulsesCreated: number;
  pulsesUpdated: number;
  eventsScanned: number;
}> {
  const db = getFirestore();
  const config = await loadConfig();
  const cutoff = Timestamp.fromDate(
    new Date(Date.now() - config.windowMinutes * 60 * 1000),
  );

  const snapshot = await db
    .collection("sensorEvents")
    .where("timestamp", ">", cutoff)
    .get();

  const events = snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      geohash: data.geohash as string,
      eventType: data.eventType as string,
    };
  });

  const clusters = clusterSensorEvents(events, config.geohashPrecision);
  let pulsesCreated = 0;
  let pulsesUpdated = 0;

  for (const cluster of clusters) {
    if (!shouldEmitPulse(cluster, config)) continue;

    const center = ngeohash.decode(cluster.geohashCell);
    const hazardId = await findLinkedHazard(
      db,
      center.latitude,
      center.longitude,
    );
    const confidence = computePulseConfidence(
      cluster.eventCount,
      hazardId != null,
    );

    const existing = await db
      .collection("guardianPulseEvents")
      .where("geohashCell", "==", cluster.geohashCell)
      .where("status", "in", ["EMERGING", "ACTIVE"])
      .limit(1)
      .get();

    const now = FieldValue.serverTimestamp();
    const payload = {
      status: "EMERGING",
      confidence,
      eventCount: cluster.eventCount,
      dominantEventType: cluster.dominantEventType,
      geohashCell: cluster.geohashCell,
      location: new GeoPoint(center.latitude, center.longitude),
      radiusMeters: DEFAULT_RADIUS_METERS,
      hazardId: hazardId ?? null,
      updatedAt: now,
    };

    if (existing.empty) {
      await db.collection("guardianPulseEvents").add({
        ...payload,
        createdAt: now,
      });
      pulsesCreated += 1;
    } else {
      await existing.docs[0].ref.update(payload);
      pulsesUpdated += 1;
    }
  }

  await resolveStalePulses(db);

  const { recomputeRoadRiskAt } = await import("../risk/calculateRoadRisk");
  for (const cluster of clusters) {
    if (!shouldEmitPulse(cluster, config)) continue;
    const center = ngeohash.decode(cluster.geohashCell);
    void recomputeRoadRiskAt(center.latitude, center.longitude).catch((err) =>
      logger.warn("Road risk recompute failed", err),
    );
  }

  return {
    pulsesCreated,
    pulsesUpdated,
    eventsScanned: events.length,
  };
}

async function findLinkedHazard(
  db: Firestore,
  lat: number,
  lng: number,
): Promise<string | null> {
  const prefix = ngeohash.encode(lat, lng, 6);
  const snapshot = await db
    .collection("hazards")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(15)
    .get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const loc = data.location as GeoPoint;
    const dist = distanceMeters(lat, lng, loc.latitude, loc.longitude);
    if (dist <= HAZARD_LINK_METERS) {
      return doc.id;
    }
  }
  return null;
}

async function resolveStalePulses(db: Firestore): Promise<void> {
  const staleCutoff = Timestamp.fromDate(
    new Date(Date.now() - 2 * 60 * 60 * 1000),
  );
  const stale = await db
    .collection("guardianPulseEvents")
    .where("status", "in", ["EMERGING", "ACTIVE"])
    .where("updatedAt", "<", staleCutoff)
    .limit(50)
    .get();

  const batch = db.batch();
  for (const doc of stale.docs) {
    batch.update(doc.ref, {
      status: "RESOLVED",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

export const detectGuardianPulse = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "europe-west1",
  },
  async () => {
    const result = await runGuardianPulseDetection();
    logger.info("Guardian Pulse scan complete", result);
  },
);

export const runGuardianPulseNow = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const result = await runGuardianPulseDetection();
    return { ok: true, ...result };
  },
);
