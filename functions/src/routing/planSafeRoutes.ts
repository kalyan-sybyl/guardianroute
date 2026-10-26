import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { riskLevelFromScore } from "../risk/riskLevels";
import {
  buildDemoDirections,
  fetchGoogleDirections,
} from "./googleDirections";
import { scoreEncodedPolyline } from "./scoreRoutePolyline";

export type RouteLabel = "FASTEST" | "BALANCED" | "SAFEST";

export interface AssessedRoute {
  routeId: string;
  label: RouteLabel;
  durationSeconds: number;
  durationMinutes: number;
  distanceMeters: number;
  distanceKm: number;
  riskScore: number;
  riskLevel: string;
  encodedPolyline: string;
  summary: string;
  criticalHazardSegments: number;
}

const planSafeRoutesSchema = {
  originLat: (v: unknown) => typeof v === "number" && v >= -90 && v <= 90,
  originLng: (v: unknown) => typeof v === "number" && v >= -180 && v <= 180,
  destLat: (v: unknown) => typeof v === "number" && v >= -90 && v <= 90,
  destLng: (v: unknown) => typeof v === "number" && v >= -180 && v <= 180,
};

export const planSafeRoutes = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const data = request.data as Record<string, unknown>;
    if (
      !planSafeRoutesSchema.originLat(data.originLat) ||
      !planSafeRoutesSchema.originLng(data.originLng) ||
      !planSafeRoutesSchema.destLat(data.destLat) ||
      !planSafeRoutesSchema.destLng(data.destLng)
    ) {
      throw new HttpsError("invalid-argument", "Invalid origin or destination.");
    }

    const originLat = data.originLat as number;
    const originLng = data.originLng as number;
    const destLat = data.destLat as number;
    const destLng = data.destLng as number;

    let routes = await fetchGoogleDirections(
      originLat,
      originLng,
      destLat,
      destLng,
    );
    let isDemo = false;

    if (routes.length === 0) {
      routes = buildDemoDirections(originLat, originLng, destLat, destLng);
      isDemo = true;
    }

    const db = getFirestore();
    const assessed: AssessedRoute[] = [];

    const demoRiskByIndex = [82, 44, 24];

    for (let i = 0; i < routes.length; i++) {
      const route = routes[i];
      let riskScore: number;
      if (isDemo) {
        riskScore = demoRiskByIndex[i] ?? 40;
      } else {
        riskScore = await scoreEncodedPolyline(db, route.encodedPolyline);
      }

      assessed.push({
        routeId: `route-${i}`,
        label: "BALANCED",
        durationSeconds: route.durationSeconds,
        durationMinutes: Math.round(route.durationSeconds / 60),
        distanceMeters: route.distanceMeters,
        distanceKm: Math.round((route.distanceMeters / 1000) * 10) / 10,
        riskScore,
        riskLevel: riskLevelFromScore(riskScore),
        encodedPolyline: route.encodedPolyline,
        summary: route.summary,
        criticalHazardSegments: riskScore >= 76 ? 1 : 0,
      });
    }

    const labeled = assignLabels(assessed);
    const recommendation = buildRecommendation(labeled);

    logger.info("planSafeRoutes", {
      routeCount: labeled.length,
      isDemo,
      recommended: recommendation.recommendedLabel,
    });

    return {
      ok: true,
      isDemo,
      routes: labeled,
      recommendation,
    };
  },
);

function assignLabels(routes: AssessedRoute[]): AssessedRoute[] {
  if (routes.length === 0) return routes;

  const fastest = [...routes].sort(
    (a, b) => a.durationSeconds - b.durationSeconds,
  )[0];
  const safest = [...routes].sort((a, b) => a.riskScore - b.riskScore)[0];

  const maxDuration = Math.max(...routes.map((r) => r.durationSeconds));
  const minDuration = Math.min(...routes.map((r) => r.durationSeconds));
  const maxRisk = Math.max(...routes.map((r) => r.riskScore));
  const minRisk = Math.min(...routes.map((r) => r.riskScore));

  let balanced = routes[0];
  let bestBalancedScore = Number.POSITIVE_INFINITY;
  for (const route of routes) {
    const normDuration =
      maxDuration === minDuration
        ? 0
        : (route.durationSeconds - minDuration) / (maxDuration - minDuration);
    const normRisk =
      maxRisk === minRisk
        ? 0
        : (route.riskScore - minRisk) / (maxRisk - minRisk);
    const score = normDuration * 0.5 + normRisk * 0.5;
    if (score < bestBalancedScore) {
      bestBalancedScore = score;
      balanced = route;
    }
  }

  return routes.map((route) => {
    let label: RouteLabel = "BALANCED";
    if (route.routeId === fastest.routeId) label = "FASTEST";
    else if (route.routeId === safest.routeId) label = "SAFEST";
    else if (route.routeId === balanced.routeId) label = "BALANCED";
    return { ...route, label };
  });
}

function buildRecommendation(routes: AssessedRoute[]): {
  recommendedLabel: RouteLabel;
  message: string;
  safestRouteId: string;
  fastestRouteId: string;
} {
  const fastest = routes.find((r) => r.label === "FASTEST") ?? routes[0];
  const safest = routes.find((r) => r.label === "SAFEST") ?? routes[0];

  const deltaMinutes = safest.durationMinutes - fastest.durationMinutes;
  const highRiskOnFastest = routes.filter(
    (r) => r.routeId === fastest.routeId && r.riskScore >= 51,
  ).length;

  let message =
    `The safer route takes approximately ${Math.max(1, deltaMinutes)} minute(s) longer but avoids high-risk road sections.`;

  if (fastest.routeId === safest.routeId) {
    message = "Only one practical route was found; safety and time are similar.";
  } else if (deltaMinutes <= 0) {
    message =
      "The safest route is also competitive on time — we recommend the safer option.";
  } else if (highRiskOnFastest > 0 && fastest.riskScore >= 60) {
    message =
      `The safer route takes approximately ${deltaMinutes} minute(s) longer but avoids two high-risk road sections.`;
  }

  return {
    recommendedLabel: safest.label,
    message,
    safestRouteId: safest.routeId,
    fastestRouteId: fastest.routeId,
  };
}
