export interface SensorEventRecord {
  geohash: string;
  eventType: string;
}

export interface PulseCluster {
  geohashCell: string;
  eventCount: number;
  dominantEventType: string;
  eventTypeCounts: Record<string, number>;
}

export interface PulseDetectionConfig {
  windowMinutes: number;
  minEvents: number;
  baselinePerHour: number;
  spikeFactor: number;
  geohashPrecision: number;
}

export function truncateGeohash(geohash: string, precision: number): string {
  return geohash.substring(0, Math.min(precision, geohash.length));
}

export function clusterSensorEvents(
  events: SensorEventRecord[],
  precision: number,
): PulseCluster[] {
  const buckets = new Map<string, Record<string, number>>();

  for (const event of events) {
    const cell = truncateGeohash(event.geohash, precision);
    const counts = buckets.get(cell) ?? {};
    counts[event.eventType] = (counts[event.eventType] ?? 0) + 1;
    buckets.set(cell, counts);
  }

  const clusters: PulseCluster[] = [];
  for (const [cell, eventTypeCounts] of buckets.entries()) {
    let dominant = "VERTICAL_SHOCK";
    let max = 0;
    let total = 0;
    for (const [type, count] of Object.entries(eventTypeCounts)) {
      total += count;
      if (count > max) {
        max = count;
        dominant = type;
      }
    }
    clusters.push({
      geohashCell: cell,
      eventCount: total,
      dominantEventType: dominant,
      eventTypeCounts,
    });
  }

  return clusters;
}

export function shouldEmitPulse(
  cluster: PulseCluster,
  config: PulseDetectionConfig,
): boolean {
  if (cluster.eventCount < config.minEvents) {
    return false;
  }
  const windowHours = config.windowMinutes / 60;
  const rate = cluster.eventCount / windowHours;
  const baseline = Math.max(2, config.baselinePerHour);
  return rate >= baseline * config.spikeFactor;
}

export function computePulseConfidence(
  eventCount: number,
  hazardLinked: boolean,
): number {
  let confidence = 0.5 + eventCount * 0.01;
  if (hazardLinked) confidence += 0.1;
  return Math.min(0.95, confidence);
}
