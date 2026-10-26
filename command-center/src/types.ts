export type LatLng = { lat: number; lng: number };

export interface HazardRecord {
  id: string;
  publicId: string;
  type: string;
  severity: string;
  status: string;
  confidence: number;
  location: LatLng;
  description: string;
  updatedAt?: Date;
  isDemo?: boolean;
}

export interface PulseRecord {
  id: string;
  status: string;
  confidence: number;
  eventCount: number;
  dominantEventType: string;
  location: LatLng;
  radiusMeters: number;
}

export interface RoadSegmentRecord {
  id: string;
  geohash: string;
  riskScore: number;
  riskLevel: string;
  location: LatLng;
}

export interface DashboardMetrics {
  activeHazards: number;
  resolvedHazards: number;
  hazardsCreatedToday: number;
  reportsToday: number;
  guardianPulseActive: number;
  sensorEventsLast24h: number;
  highRiskAreas: number;
  elevatedRiskAreas: number;
  roadSegmentsTracked: number;
  hazardSeverityDistribution: {
    low: number;
    moderate: number;
    high: number;
    critical: number;
  };
  generatedAt: string;
}
