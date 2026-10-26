import { useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  query,
  where,
  orderBy,
  limit,
  type GeoPoint,
  type Timestamp,
} from "firebase/firestore";
import { db } from "../firebase";
import { demoOverlayEnabled } from "../config";
import { kampalaDemoHazards } from "../demoData";
import type { HazardRecord, PulseRecord, RoadSegmentRecord } from "../types";

const ACTIVE_HAZARD_STATUSES = ["ACTIVE", "VERIFIED", "REPORTED", "DETECTED"];

function geoToLatLng(location: unknown): { lat: number; lng: number } | null {
  if (!location) return null;
  if (typeof location === "object" && "latitude" in location) {
    const gp = location as GeoPoint;
    return { lat: gp.latitude, lng: gp.longitude };
  }
  return null;
}

function tsToDate(value: unknown): Date | undefined {
  if (value && typeof value === "object" && "toDate" in value) {
    return (value as Timestamp).toDate();
  }
  return undefined;
}

export function useLiveHazards() {
  const [hazards, setHazards] = useState<HazardRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "hazards"),
      where("status", "in", ACTIVE_HAZARD_STATUSES),
      limit(150),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: HazardRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            publicId: (data.publicId as string) ?? doc.id,
            type: (data.type as string) ?? "OTHER",
            severity: (data.severity as string) ?? "MODERATE",
            status: (data.status as string) ?? "ACTIVE",
            confidence: (data.confidence as number) ?? 0.5,
            location,
            description: (data.description as string) ?? "Road hazard",
            updatedAt: tsToDate(data.updatedAt),
          });
        });
        if (rows.length === 0 && demoOverlayEnabled()) {
          setHazards(kampalaDemoHazards());
        } else {
          setHazards(rows);
        }
        setLoading(false);
        setError(null);
      },
      (err) => {
        setError(err.message);
        if (demoOverlayEnabled()) {
          setHazards(kampalaDemoHazards());
        }
        setLoading(false);
      },
    );

    return () => unsub();
  }, []);

  return { hazards, loading, error };
}

export function useLivePulses() {
  const [pulses, setPulses] = useState<PulseRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "guardianPulseEvents"),
      where("status", "in", ["EMERGING", "ACTIVE"]),
      orderBy("updatedAt", "desc"),
      limit(40),
    );

    const unsub = onSnapshot(q, (snap) => {
      const rows: PulseRecord[] = [];
      snap.forEach((doc) => {
        const data = doc.data();
        const location = geoToLatLng(data.location);
        if (!location) return;
        rows.push({
          id: doc.id,
          status: (data.status as string) ?? "ACTIVE",
          confidence: (data.confidence as number) ?? 0.5,
          eventCount: (data.eventCount as number) ?? 0,
          dominantEventType: (data.dominantEventType as string) ?? "UNKNOWN",
          location,
          radiusMeters: (data.radiusMeters as number) ?? 40,
        });
      });
      setPulses(rows);
    });

    return () => unsub();
  }, []);

  return pulses;
}

export function useLiveRoadRisk() {
  const [segments, setSegments] = useState<RoadSegmentRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "roadSegments"),
      where("riskScore", ">=", 26),
      orderBy("riskScore", "desc"),
      limit(80),
    );

    const unsub = onSnapshot(q, (snap) => {
      const rows: RoadSegmentRecord[] = [];
      snap.forEach((doc) => {
        const data = doc.data();
        const location = geoToLatLng(data.location);
        if (!location) return;
        rows.push({
          id: doc.id,
          geohash: (data.geohash as string) ?? doc.id,
          riskScore: (data.riskScore as number) ?? 0,
          riskLevel: (data.riskLevel as string) ?? "LOW",
          location,
        });
      });
      setSegments(rows);
    });

    return () => unsub();
  }, []);

  return segments;
}

export function useRecentResolvedHazards() {
  const [resolved, setResolved] = useState<HazardRecord[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, "hazards"),
      where("status", "in", ["RESOLVED", "STALE"]),
      orderBy("updatedAt", "desc"),
      limit(12),
    );

    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: HazardRecord[] = [];
        snap.forEach((doc) => {
          const data = doc.data();
          const location = geoToLatLng(data.location);
          if (!location) return;
          rows.push({
            id: doc.id,
            publicId: (data.publicId as string) ?? doc.id,
            type: (data.type as string) ?? "OTHER",
            severity: (data.severity as string) ?? "MODERATE",
            status: (data.status as string) ?? "RESOLVED",
            confidence: (data.confidence as number) ?? 0.5,
            location,
            description: (data.description as string) ?? "",
            updatedAt: tsToDate(data.updatedAt),
          });
        });
        setResolved(rows);
      },
      () => setResolved([]),
    );

    return () => unsub();
  }, []);

  return resolved;
}
