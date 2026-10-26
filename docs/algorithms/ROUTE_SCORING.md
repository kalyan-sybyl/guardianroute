# Route risk scoring (Phase 7)

## Server function: `planSafeRoutes`

**Input:** `originLat`, `originLng`, `destLat`, `destLng` (authenticated)

**Steps:**

1. Fetch up to 3 alternatives from **Google Directions** (`alternatives=true`), or **demo routes** if no API key.
2. Decode each `overview_polyline` and sample every **50 m**.
3. For each sample, read `roadSegments/{geohash7}` or infer from nearby hazards.
4. Compute route score:

```text
routeRisk = clamp(
  avg(sampleScores) × 0.60
  + max(sampleScores) × 0.25
  + min(1, criticalSegments/3) × 0.15
) × 100
```

(`critical` = sample score ≥ 76)

5. Label **FASTEST** (min duration), **SAFEST** (min risk), **BALANCED** (best 50/50 normalized time+risk).
6. Return recommendation copy for the UI.

## Mobile

- **Navigate** → `/map/routes` (comparison screen)
- Selected route draws a **polyline** on the home map (`selectedRouteProvider`)

## Configuration

Set `GOOGLE_MAPS_API_KEY` (or `DIRECTIONS_API_KEY`) on Cloud Functions for live Directions. Enable **Directions API** in Google Cloud.
