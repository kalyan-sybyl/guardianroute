import { distanceMeters } from "../geo/distance";

export interface LatLng {
  latitude: number;
  longitude: number;
}

/** Decodes a Google encoded polyline string. */
export function decodePolyline(encoded: string): LatLng[] {
  const points: LatLng[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += deltaLat;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += deltaLng;

    points.push({ latitude: lat / 1e5, longitude: lng / 1e5 });
  }

  return points;
}

export function samplePolylineEveryMeters(
  points: LatLng[],
  intervalMeters: number,
): LatLng[] {
  if (points.length < 2) return points;

  const samples: LatLng[] = [points[0]];
  let accumulated = 0;

  for (let i = 1; i < points.length; i++) {
    const a = points[i - 1];
    const b = points[i];
    const segLen = distanceMeters(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    if (segLen <= 0) continue;

    let start = accumulated;
    accumulated += segLen;
    while (start + intervalMeters <= accumulated) {
      const t = (start + intervalMeters - (accumulated - segLen)) / segLen;
      samples.push(interpolate(a, b, t));
      start += intervalMeters;
    }
  }

  const last = points[points.length - 1];
  const prev = samples[samples.length - 1];
  if (
    distanceMeters(
      prev.latitude,
      prev.longitude,
      last.latitude,
      last.longitude,
    ) > 1
  ) {
    samples.push(last);
  }

  return samples;
}

function interpolate(a: LatLng, b: LatLng, t: number): LatLng {
  return {
    latitude: a.latitude + (b.latitude - a.latitude) * t,
    longitude: a.longitude + (b.longitude - a.longitude) * t,
  };
}
