import { Firestore, GeoPoint } from "firebase-admin/firestore";
import ngeohash from "ngeohash";
import { distanceMeters } from "../geo/distance";
import { severityToFactor } from "../risk/riskLevels";
import { decodePolyline, samplePolylineEveryMeters } from "./polyline";
import { computeRouteRiskScore } from "./routeRisk";

const SAMPLE_INTERVAL_METERS = 50;
const HAZARD_LOOKUP_METERS = 100;

export async function scoreEncodedPolyline(
  db: Firestore,
  encodedPolyline: string,
): Promise<number> {
  const points = decodePolyline(encodedPolyline);
  const samples = samplePolylineEveryMeters(points, SAMPLE_INTERVAL_METERS);
  const scores: number[] = [];

  const segmentCache = new Map<string, number>();

  for (const point of samples) {
    const cell = ngeohash.encode(point.latitude, point.longitude, 7);
    let score = segmentCache.get(cell);
    if (score == null) {
      score = await riskScoreForCell(db, cell, point.latitude, point.longitude);
      segmentCache.set(cell, score);
    }
    scores.push(score);
  }

  return computeRouteRiskScore(scores);
}

async function riskScoreForCell(
  db: Firestore,
  cell: string,
  lat: number,
  lng: number,
): Promise<number> {
  const segmentSnap = await db.collection("roadSegments").doc(cell).get();
  if (segmentSnap.exists) {
    return (segmentSnap.data()?.riskScore as number) ?? 25;
  }

  const prefix = cell.substring(0, 6);
  const hazardSnap = await db
    .collection("hazards")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(20)
    .get();

  let maxRisk = 20;
  for (const doc of hazardSnap.docs) {
    const data = doc.data();
    const loc = data.location as GeoPoint;
    const dist = distanceMeters(lat, lng, loc.latitude, loc.longitude);
    if (dist > HAZARD_LOOKUP_METERS) continue;

    const severity = severityToFactor(data.severity as string);
    const confidence = (data.confidence as number) ?? 0.5;
    const hazardScore = Math.round(severity * confidence * 100);
    maxRisk = Math.max(maxRisk, hazardScore);
  }

  return maxRisk;
}
