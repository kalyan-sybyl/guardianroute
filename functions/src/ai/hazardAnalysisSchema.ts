import { z } from "zod";

export const HAZARD_TYPES = [
  "POTHOLE",
  "ROAD_DAMAGE",
  "FLOODING",
  "ROAD_OBSTRUCTION",
  "ACCIDENT",
  "DANGEROUS_INTERSECTION",
  "CONSTRUCTION",
  "OTHER",
] as const;

export const SEVERITIES = ["LOW", "MODERATE", "HIGH", "CRITICAL"] as const;

export const hazardAnalysisSchema = z.object({
  hazardType: z.enum(HAZARD_TYPES),
  severity: z.enum(SEVERITIES),
  confidence: z.number().min(0).max(1),
  description: z.string().min(3).max(500),
  recommendedAction: z.string().min(3).max(500),
});

export type HazardAnalysis = z.infer<typeof hazardAnalysisSchema>;

export function parseHazardAnalysis(raw: unknown): HazardAnalysis {
  const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
  return hazardAnalysisSchema.parse(parsed);
}
