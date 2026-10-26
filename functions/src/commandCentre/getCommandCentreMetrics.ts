import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  getFirestore,
  Timestamp,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";

const ACTIVE_HAZARD_STATUSES = ["ACTIVE", "VERIFIED", "REPORTED", "DETECTED"];
const RESOLVED_HAZARD_STATUSES = ["RESOLVED", "STALE"];

function startOfUtcDay(): Date {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

function severityBucket(severity: string | undefined): string {
  const s = (severity ?? "MODERATE").toUpperCase();
  if (s === "CRITICAL") return "critical";
  if (s === "HIGH") return "high";
  if (s === "LOW") return "low";
  return "moderate";
}

export const getCommandCentreMetrics = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const db = getFirestore();
    const dayStart = startOfUtcDay();
    const last24h = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const [
      hazardsSnap,
      pulsesSnap,
      segmentsSnap,
      sensorSnap,
      reportsSnap,
    ] = await Promise.all([
      db.collection("hazards").limit(400).get(),
      db
        .collection("guardianPulseEvents")
        .where("status", "in", ["EMERGING", "ACTIVE"])
        .get(),
      db.collection("roadSegments").orderBy("riskScore", "desc").limit(200).get(),
      db
        .collection("sensorEvents")
        .where("timestamp", ">=", Timestamp.fromDate(last24h))
        .get(),
      db
        .collection("hazardReports")
        .where("createdAt", ">=", Timestamp.fromDate(dayStart))
        .get()
        .catch(() => null),
    ]);

    let activeHazards = 0;
    let resolvedHazards = 0;
    let hazardsToday = 0;
    const riskDistribution = { low: 0, moderate: 0, high: 0, critical: 0 };

    for (const doc of hazardsSnap.docs) {
      const data = doc.data();
      const status = (data.status as string | undefined)?.toUpperCase() ?? "";
      if (ACTIVE_HAZARD_STATUSES.includes(status)) {
        activeHazards += 1;
        const bucket = severityBucket(data.severity as string | undefined);
        riskDistribution[bucket as keyof typeof riskDistribution] += 1;
      }
      if (RESOLVED_HAZARD_STATUSES.includes(status)) {
        resolvedHazards += 1;
      }
      const createdAt = data.createdAt as Timestamp | undefined;
      if (createdAt && createdAt.toDate() >= dayStart) {
        hazardsToday += 1;
      }
    }

    const segmentScores = segmentsSnap.docs.map(
      (d: QueryDocumentSnapshot) => (d.data().riskScore as number) ?? 0,
    );
    const highRiskAreas = segmentScores.filter((s) => s >= 76).length;
    const elevatedRiskAreas = segmentScores.filter((s) => s >= 50).length;

    const reportsToday =
      reportsSnap === null
        ? hazardsToday
        : reportsSnap.size;

    return {
      activeHazards,
      resolvedHazards,
      hazardsCreatedToday: hazardsToday,
      reportsToday,
      guardianPulseActive: pulsesSnap.size,
      sensorEventsLast24h: sensorSnap.size,
      highRiskAreas,
      elevatedRiskAreas,
      roadSegmentsTracked: segmentsSnap.size,
      hazardSeverityDistribution: riskDistribution,
      generatedAt: new Date().toISOString(),
    };
  },
);
