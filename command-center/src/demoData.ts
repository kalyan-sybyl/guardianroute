import type { HazardRecord } from "./types";
import { KAMPALA_CENTER } from "./config";

export function kampalaDemoHazards(): HazardRecord[] {
  const { lat, lng } = KAMPALA_CENTER;
  return [
    {
      id: "demo-1",
      publicId: "GR-D01",
      type: "POTHOLE",
      severity: "HIGH",
      status: "ACTIVE",
      confidence: 0.94,
      location: { lat: lat + 0.008, lng: lng + 0.012 },
      description: "Large pothole affecting the motorcycle travel path.",
      isDemo: true,
    },
    {
      id: "demo-2",
      publicId: "GR-D02",
      type: "ROAD_DAMAGE",
      severity: "MODERATE",
      status: "ACTIVE",
      confidence: 0.78,
      location: { lat: lat - 0.006, lng: lng - 0.009 },
      description: "Uneven road surface near junction.",
      isDemo: true,
    },
    {
      id: "demo-3",
      publicId: "GR-D03",
      type: "DANGEROUS_INTERSECTION",
      severity: "CRITICAL",
      status: "VERIFIED",
      confidence: 0.88,
      location: { lat: lat + 0.004, lng: lng - 0.015 },
      description: "Poor visibility and heavy merging traffic.",
      isDemo: true,
    },
  ];
}
