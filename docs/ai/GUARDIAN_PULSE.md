# Guardian Pulse™

## Purpose

Detect **emerging road hazards** from clustered anonymous sensor events before (or without) a photo report.

## Pipeline

```text
sensorEvents (30 min window)
        ↓
geohash clustering (precision 7)
        ↓
threshold: count ≥ minEvents AND rate ≥ baseline × spikeFactor
        ↓
guardianPulseEvents (EMERGING)
        ↓
optional link to hazard within 75 m
```

## Cloud Functions

| Function | Trigger |
|----------|---------|
| `detectGuardianPulse` | Scheduled every **5 minutes** |
| `runGuardianPulseNow` | Callable (authenticated) for demos / manual scan |

## Mobile

- Purple **circles** + markers on the map
- **Safety** screen (`/safety`) lists active pulses and can run a scan
- Demo pulse shown in dev/demo when Firestore is empty

## Tuning (Remote Config — future)

Defaults are coded in `pulseClustering.ts` / `loadConfig()` (30 min window, 15 min events, 4× spike over 2 events/hour baseline).
