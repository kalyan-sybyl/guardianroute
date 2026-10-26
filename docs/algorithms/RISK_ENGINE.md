# Road risk engine (Phase 6)

## Score

Each **road segment** (geohash precision **7**) receives `riskScore` **0–100** and `riskLevel`:

| Score | Level |
|-------|--------|
| 0–25 | LOW |
| 26–50 | MODERATE |
| 51–75 | HIGH |
| 76–100 | CRITICAL |

## Components (0.0–1.0)

| Component | Default weight | Source |
|-----------|----------------|--------|
| Hazard severity | 0.30 | Nearby active hazards × confidence |
| Harsh braking | 0.20 | `HARSH_BRAKING` sensor events (24 h) |
| Sensor anomalies | 0.15 | Other sensor events |
| Verified reports | 0.15 | Report + confirmation counts |
| Environmental | 0.10 | `FLOODING` hazards |
| Time of day | 0.05 | Night hours (EAT) |
| Historical | 0.05 | Resolved hazard signal |

```text
riskScore = round(clamp(sum(component × weight) × 100, 0, 100))
```

Weights: `config/riskEngine` in Firestore (optional) or defaults in `riskWeights.ts`.  
Mobile Remote Config mirrors defaults for display (`risk_*_weight` keys).

## Cloud Functions

| Function | Role |
|----------|------|
| `calculateRoadRiskScheduled` | Every **15 min** — recompute cells with recent hazards/sensors |
| `runRoadRiskRecalculation` | Callable — full batch or single lat/lng |
| Auto hooks | After hazard analysis, sensor upload, Guardian Pulse scan |

## Firestore

`roadSegments/{geohash7}` — **server write only**; clients read for map overlay and Safety screen.

## Mobile

- Colored **risk circles** on map (toggle in Safety)
- Safety → **Recalculate road risk** + top segments list
