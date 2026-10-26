import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import {
  geohashCellFromLatLng,
  loadRiskWeights,
  recomputeRoadSegment,
} from "./recomputeRoadSegment";

export async function recomputeRoadRiskAt(
  latitude: number,
  longitude: number,
): Promise<{ segmentId: string }> {
  const db = getFirestore();
  const weights = await loadRiskWeights(db);
  const cell = geohashCellFromLatLng(latitude, longitude);
  await recomputeRoadSegment(db, cell, weights);
  return { segmentId: cell };
}

export async function recomputeRecentActiveSegments(): Promise<{
  segmentsUpdated: number;
}> {
  const db = getFirestore();
  const weights = await loadRiskWeights(db);
  const cells = new Set<string>();

  const since = Timestamp.fromDate(
    new Date(Date.now() - 24 * 60 * 60 * 1000),
  );

  const sensors = await db
    .collection("sensorEvents")
    .where("timestamp", ">", since)
    .limit(300)
    .get();

  for (const doc of sensors.docs) {
    const gh = doc.data().geohash as string;
    if (gh) cells.add(gh.substring(0, 7));
  }

  const hazards = await db
    .collection("hazards")
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(100)
    .get();

  for (const doc of hazards.docs) {
    const gh = doc.data().geohash as string;
    if (gh) cells.add(gh.substring(0, 7));
  }

  let segmentsUpdated = 0;
  for (const cell of cells) {
    await recomputeRoadSegment(db, cell, weights);
    segmentsUpdated += 1;
  }

  return { segmentsUpdated };
}

export const calculateRoadRiskScheduled = onSchedule(
  {
    schedule: "every 15 minutes",
    region: "europe-west1",
  },
  async () => {
    const result = await recomputeRecentActiveSegments();
    logger.info("Road risk recalculation complete", result);
  },
);

export const runRoadRiskRecalculation = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const data = request.data as { latitude?: number; longitude?: number } | null;

    if (data?.latitude != null && data?.longitude != null) {
      const single = await recomputeRoadRiskAt(data.latitude, data.longitude);
      return { ok: true, ...single };
    }

    const batch = await recomputeRecentActiveSegments();
    return { ok: true, ...batch };
  },
);
