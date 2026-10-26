# Command Centre (Phase 9)

## Purpose

A **lightweight web dashboard** for judges and operators — visually impressive without blocking the Flutter rider app.

Displays:

| Area | Source |
|------|--------|
| Live map | Google Maps JS + Firestore streams |
| Active hazards | `hazards` (status in ACTIVE, VERIFIED, …) |
| Guardian Pulse™ | `guardianPulseEvents` (EMERGING, ACTIVE) |
| High-risk areas | `roadSegments` (risk score circles) |
| Reports today | `getCommandCentreMetrics` (hazardReports + fallbacks) |
| Sensor events (24h) | `getCommandCentreMetrics` (admin read of `sensorEvents`) |
| Risk distribution | Aggregated active hazard severities |
| Recent / resolved hazards | Firestore lists |

## Security model

- Operators **sign in with Google** (Firebase Auth).
- Client reads only collections allowed by [firebase/firestore.rules](../firebase/firestore.rules).
- **Sensor events** are not readable from the browser; counts come from the **`getCommandCentreMetrics`** callable (Admin SDK).

## Local development

See [command-center/README.md](../command-center/README.md).

## Hosting

Static build output: `command-center/dist`  
Configured in root `firebase.json` under `hosting`.

```bash
cd command-center && npm run build
firebase deploy --only hosting
```

Add your Hosting domain to Firebase **Authentication → Settings → Authorized domains** if you use a custom URL.

## Demo overlay

When Firestore has no hazards, the UI can show **Kampala demo hazards** (same story as the mobile app) if `VITE_DEMO_OVERLAY` is not `false`.

## Google Maps

- Enable **Maps JavaScript API**.
- Use `mapId: DEMO_MAP_ID` for development markers; for production polish, create a Map ID in Google Cloud Console.
