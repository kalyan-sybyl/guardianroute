import { initializeApp } from "firebase-admin/app";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();

setGlobalOptions({ region: "europe-west1" });

export const ping = onCall(async () => {
  return {
    ok: true,
    service: "guardianroute-functions",
    timestamp: new Date().toISOString(),
  };
});

export const ensureUserProfile = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const { getFirestore, FieldValue } = await import("firebase-admin/firestore");
  const db = getFirestore();
  const uid = request.auth.uid;
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();

  if (!snap.exists) {
    const displayName =
      request.auth.token.name ?? request.auth.token.email ?? "Rider";
    await ref.set({
      displayName,
      createdAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    });
  } else {
    await ref.update({
      lastActiveAt: FieldValue.serverTimestamp(),
    });
  }

  return { uid };
});

export { analyzeHazardReport } from "./hazards/analyzeHazardReport";
export { processSensorEvent } from "./sensors/processSensorEvent";
export {
  detectGuardianPulse,
  runGuardianPulseNow,
} from "./guardianPulse/detectGuardianPulse";
export {
  calculateRoadRiskScheduled,
  runRoadRiskRecalculation,
} from "./risk/calculateRoadRisk";
export { planSafeRoutes } from "./routing/planSafeRoutes";
export { getCommandCentreMetrics } from "./commandCentre/getCommandCentreMetrics";
