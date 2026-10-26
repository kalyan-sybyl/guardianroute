import {
  FieldValue,
  Firestore,
  GeoPoint,
  Timestamp,
} from "firebase-admin/firestore";
import ngeohash from "ngeohash";
import { distanceMeters } from "../geo/distance";
import { computeRoadRisk, normalizeCount, RoadRiskComponents } from "./roadRisk";
import { DEFAULT_RISK_WEIGHTS, RiskWeights } from "./riskWeights";
import { severityToFactor } from "./riskLevels";

const SEGMENT_PRECISION = 7;
const SENSOR_WINDOW_HOURS = 24;
const HAZARD_RADIUS_METERS = 120;

export async function loadRiskWeights(db: Firestore): Promise<RiskWeights> {
  const snap = await db.collection("config").doc("riskEngine").get();
  if (!snap.exists) return DEFAULT_RISK_WEIGHTS;
  const data = snap.data() ?? {};
  return {
    hazard: (data.risk_hazard_weight as number) ?? DEFAULT_RISK_WEIGHTS.hazard,
    harshBraking:
      (data.risk_harsh_braking_weight as number) ??
      DEFAULT_RISK_WEIGHTS.harshBraking,
    sensorAnomalies:
      (data.risk_sensor_anomalies_weight as number) ??
      DEFAULT_RISK_WEIGHTS.sensorAnomalies,
    verifiedReports:
      (data.risk_verified_reports_weight as number) ??
      DEFAULT_RISK_WEIGHTS.verifiedReports,
    environmental:
      (data.risk_environmental_weight as number) ??
      DEFAULT_RISK_WEIGHTS.environmental,
    timeOfDay:
      (data.risk_time_weight as number) ?? DEFAULT_RISK_WEIGHTS.timeOfDay,
    historical:
      (data.risk_historical_weight as number) ??
      DEFAULT_RISK_WEIGHTS.historical,
  };
}

export async function recomputeRoadSegment(
  db: Firestore,
  geohashCell: string,
  weights: RiskWeights = DEFAULT_RISK_WEIGHTS,
): Promise<void> {
  const cell = geohashCell.substring(0, SEGMENT_PRECISION);
  const center = ngeohash.decode(cell);

  const components = await gatherComponents(db, cell, center.latitude, center.longitude);
  const result = computeRoadRisk(components, weights);

  const segmentId = cell;
  await db.collection("roadSegments").doc(segmentId).set(
    {
      geohash: cell,
      location: new GeoPoint(center.latitude, center.longitude),
      riskScore: result.riskScore,
      riskLevel: result.riskLevel,
      components: result.components,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function gatherComponents(
  db: Firestore,
  cell: string,
  lat: number,
  lng: number,
): Promise<RoadRiskComponents> {
  const prefix = cell.substring(0, Math.min(6, cell.length));
  const hazardSnap = await db
    .collection("hazards")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(40)
    .get();

  let hazardSeverity = 0;
  let verifiedReports = 0;
  let environmental = 0;
  let historical = 0;

  for (const doc of hazardSnap.docs) {
    const data = doc.data();
    const loc = data.location as GeoPoint;
    const dist = distanceMeters(lat, lng, loc.latitude, loc.longitude);
    if (dist > HAZARD_RADIUS_METERS) continue;

    const severity = severityToFactor(data.severity as string);
    const confidence = (data.confidence as number) ?? 0.5;
    hazardSeverity = Math.max(hazardSeverity, severity * confidence);

    const reports = (data.reportCount as number) ?? 0;
    const confirmations = (data.confirmationCount as number) ?? 0;
    verifiedReports = Math.max(
      verifiedReports,
      normalizeCount(reports + confirmations * 0.5, 10),
    );

    if ((data.type as string) === "FLOODING") {
      environmental = Math.max(environmental, 0.8 * confidence);
    }

    if ((data.status as string) === "RESOLVED") {
      historical = Math.max(historical, 0.3);
    }
  }

  const sensorCutoffMs =
    Date.now() - SENSOR_WINDOW_HOURS * 60 * 60 * 1000;
  const sensorSnap = await db
    .collection("sensorEvents")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .limit(200)
    .get();

  let harshCount = 0;
  let anomalyCount = 0;
  for (const doc of sensorSnap.docs) {
    const data = doc.data();
    const ts = data.timestamp as Timestamp | undefined;
    if (ts && ts.toMillis() < sensorCutoffMs) continue;

    const loc = data.location as GeoPoint;
    const dist = distanceMeters(lat, lng, loc.latitude, loc.longitude);
    if (dist > HAZARD_RADIUS_METERS) continue;

    const type = data.eventType as string;
    if (type === "HARSH_BRAKING") harshCount += 1;
    else anomalyCount += 1;
  }

  const timeOfDay = computeTimeRisk();

  return {
    hazardSeverity,
    harshBraking: normalizeCount(harshCount, 8),
    sensorAnomalies: normalizeCount(anomalyCount, 15),
    verifiedReports,
    environmental,
    timeOfDay,
    historical,
  };
}

/** Uganda (EAT, UTC+3) night factor 19:00–05:00 */
function computeTimeRisk(): number {
  const hour = (new Date().getUTCHours() + 3) % 24;
  if (hour >= 19 || hour < 5) return 0.3;
  return 0.05;
}

export function geohashCellFromLatLng(lat: number, lng: number): string {
  return ngeohash.encode(lat, lng, SEGMENT_PRECISION);
}
