import { z } from "zod";

export const SENSOR_EVENT_TYPES = [
  "HARSH_BRAKING",
  "VERTICAL_SHOCK",
  "ABNORMAL_VIBRATION",
  "SUDDEN_AVOIDANCE",
] as const;

export const submitSensorEventSchema = z.object({
  anonymousDeviceId: z.string().min(8).max(64),
  eventType: z.enum(SENSOR_EVENT_TYPES),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  magnitude: z.number().min(0).max(100),
  speed: z.number().min(0).max(120).optional(),
  heading: z.number().min(0).max(360).optional(),
  clientTimestamp: z.string().datetime().optional(),
});

export type SubmitSensorEventInput = z.infer<typeof submitSensorEventSchema>;
