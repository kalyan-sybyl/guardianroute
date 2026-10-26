import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  FieldValue,
  GeoPoint,
  Firestore,
} from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import type { Bucket } from "@google-cloud/storage";
import ngeohash from "ngeohash";
import { analyzeHazardMedia } from "../ai/gemini";
import { HazardAnalysis } from "../ai/hazardAnalysisSchema";
import { distanceMeters } from "../geo/distance";

const DEDUPE_RADIUS_METERS = 50;
const DEDUPE_WINDOW_HOURS = 48;

interface HazardReportDoc {
  userId: string;
  status: string;
  location: GeoPoint;
  imageStoragePath: string;
  audioStoragePath?: string;
  transcript?: string;
  heading?: number;
  speed?: number;
}

export const analyzeHazardReport = onDocumentCreated(
  {
    document: "hazardReports/{reportId}",
    region: "europe-west1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const reportId = event.params.reportId;
    const data = snap.data() as HazardReportDoc;

    if (data.status !== "PENDING") {
      return;
    }

    const db = getFirestore();
    const reportRef = snap.ref;

    await reportRef.update({
      status: "ANALYZING",
      updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      const bucket = getStorage().bucket();
      const imageFile = bucket.file(data.imageStoragePath);
      const [imageBuffer] = await imageFile.download();
      const [metadata] = await imageFile.getMetadata();
      const mimeType = metadata.contentType ?? "image/jpeg";

      let audioBase64: string | undefined;
      let audioMimeType: string | undefined;
      if (data.audioStoragePath) {
        const audioFile = bucket.file(data.audioStoragePath);
        const [audioBuffer] = await audioFile.download();
        const [audioMeta] = await audioFile.getMetadata();
        audioBase64 = audioBuffer.toString("base64");
        audioMimeType = audioMeta.contentType ?? "audio/mp4";
      }

      const analysis = await analyzeHazardMedia({
        imageBase64: imageBuffer.toString("base64"),
        imageMimeType: mimeType,
        audioBase64,
        audioMimeType,
        transcript: data.transcript,
        latitude: data.location.latitude,
        longitude: data.location.longitude,
        heading: data.heading,
        speed: data.speed,
      });

      const hazardId = await upsertHazard({
        db,
        bucket,
        reportId,
        userId: data.userId,
        location: data.location,
        analysis,
        imageStoragePath: data.imageStoragePath,
      });

      await reportRef.update({
        status: "COMPLETED",
        hazardId,
        analysis,
        updatedAt: FieldValue.serverTimestamp(),
      });

      const { recomputeRoadRiskAt } = await import("../risk/calculateRoadRisk");
      void recomputeRoadRiskAt(
        data.location.latitude,
        data.location.longitude,
      ).catch((err) => logger.warn("Road risk recompute failed", err));

      logger.info("Hazard report analyzed", { reportId, hazardId });
    } catch (error) {
      logger.error("Hazard analysis failed", { reportId, error });
      await reportRef.update({
        status: "FAILED",
        error: error instanceof Error ? error.message : String(error),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  },
);

async function upsertHazard(params: {
  db: Firestore;
  bucket: Bucket;
  reportId: string;
  userId: string;
  location: GeoPoint;
  analysis: HazardAnalysis;
  imageStoragePath: string;
}): Promise<string> {
  const { db, bucket, reportId, userId, location, analysis, imageStoragePath } =
    params;

  const duplicate = await findDuplicateHazard(
    db,
    location.latitude,
    location.longitude,
    analysis.hazardType,
  );

  const now = FieldValue.serverTimestamp();
  const geohash = ngeohash.encode(location.latitude, location.longitude, 9);

  if (duplicate) {
    const hazardRef = db.collection("hazards").doc(duplicate.id);
    await hazardRef.update({
      severity: analysis.severity,
      confidence: Math.min(
        0.99,
        Math.max(duplicate.confidence, analysis.confidence),
      ),
      description: analysis.description,
      recommendedAction: analysis.recommendedAction,
      reportCount: FieldValue.increment(1),
      lastVerifiedAt: now,
      updatedAt: now,
    });

    await hazardRef.collection("reports").doc(reportId).set({
      userId,
      reportId,
      createdAt: now,
    });

    await copyImageToHazard(bucket, imageStoragePath, duplicate.id, reportId);
    return duplicate.id;
  }

  const publicId = await nextPublicId(db);
  const hazardRef = db.collection("hazards").doc();
  await hazardRef.set({
    publicId,
    type: analysis.hazardType,
    severity: analysis.severity,
    confidence: analysis.confidence,
    status: "ACTIVE",
    lifecycle: "REPORTED",
    location,
    geohash,
    description: analysis.description,
    recommendedAction: analysis.recommendedAction,
    ai: {
      model: "gemini-2.0-flash",
      analyzedAt: now,
    },
    reportCount: 1,
    confirmationCount: 0,
    sensorEvidenceCount: 0,
    firstDetectedAt: now,
    lastVerifiedAt: now,
    createdAt: now,
    updatedAt: now,
  });

  await hazardRef.collection("reports").doc(reportId).set({
    userId,
    reportId,
    createdAt: now,
  });

  await copyImageToHazard(bucket, imageStoragePath, hazardRef.id, reportId);
  return hazardRef.id;
}

async function copyImageToHazard(
  bucket: Bucket,
  sourcePath: string,
  hazardId: string,
  reportId: string,
): Promise<void> {
  const dest = `hazards/${hazardId}/images/${reportId}.jpg`;
  await bucket.file(sourcePath).copy(bucket.file(dest));
}

async function findDuplicateHazard(
  db: Firestore,
  lat: number,
  lng: number,
  hazardType: string,
): Promise<{ id: string; confidence: number } | null> {
  const prefix = ngeohash.encode(lat, lng, 6);
  const snapshot = await db
    .collection("hazards")
    .where("geohash", ">=", prefix)
    .where("geohash", "<=", `${prefix}\uf8ff`)
    .where("status", "in", ["ACTIVE", "VERIFIED", "REPORTED"])
    .limit(25)
    .get();

  const cutoff = Date.now() - DEDUPE_WINDOW_HOURS * 60 * 60 * 1000;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.type !== hazardType) continue;

    const updatedAt = data.updatedAt?.toDate?.() as Date | undefined;
    if (updatedAt && updatedAt.getTime() < cutoff) continue;

    const loc = data.location as GeoPoint;
    const dist = distanceMeters(lat, lng, loc.latitude, loc.longitude);
    if (dist <= DEDUPE_RADIUS_METERS) {
      return {
        id: doc.id,
        confidence: (data.confidence as number) ?? 0.5,
      };
    }
  }

  return null;
}

async function nextPublicId(db: FirebaseFirestore.Firestore): Promise<string> {
  const counterRef = db.collection("config").doc("hazardCounter");
  const next = await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = (snap.data()?.value as number) ?? 200;
    const value = current + 1;
    tx.set(counterRef, { value }, { merge: true });
    return value;
  });
  return `GR-${next}`;
}
