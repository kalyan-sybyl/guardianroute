# Sensor detection (Phase 4)

## Principles

- Process **user accelerometer** and **gyroscope** on-device.
- Upload only classified events (no raw streams).
- Use **anonymous device ID** (install UUID) — not linked to trip history.
- **60s cooldown** per event type (client + server).

## Event types

| Type | Local signal |
|------|----------------|
| `VERTICAL_SHOCK` | \|userAccel.z\| ≥ threshold |
| `HARSH_BRAKING` | userAccel.y ≤ −threshold or GPS deceleration |
| `ABNORMAL_VIBRATION` | Gyro magnitude variance over ~25 samples |
| `SUDDEN_AVOIDANCE` | \|userAccel.x\| ≥ threshold while speed ≥ min |

Thresholds are tunable via Firebase Remote Config (see `bootstrap.dart` defaults).

## Upload path

```text
SensorMonitor → httpsCallable(processSensorEvent) → sensorEvents
                                              → correlate nearby hazards (+sensorEvidenceCount)
```

## UX

Profile → **Road Guardian sensors** toggle. Monitoring runs only while the **map screen** is visible and the toggle is on.
