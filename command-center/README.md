# GuardianRoute Command Centre (Phase 9)

Web dashboard for hackathon demos: **live map**, **hazards**, **Guardian Pulse™**, **road risk**, and **server-side analytics** (including sensor events not exposed in Firestore client rules).

## Stack

- Vite + React + TypeScript
- Firebase Auth (Google) + Firestore listeners
- Callable `getCommandCentreMetrics` (Cloud Functions)
- Google Maps (`@vis.gl/react-google-maps`)

## Setup

1. Copy env file:

   ```bash
   cd command-center
   cp .env.example .env
   ```

2. Fill `.env` from Firebase console → Project settings → **Your apps** → Web app config (create a web app if needed). Use the same project as the Flutter app.

3. Set `VITE_GOOGLE_MAPS_API_KEY` with **Maps JavaScript API** enabled (separate or shared browser key).

4. Install and run:

   ```bash
   npm install
   npm run dev
   ```

5. Sign in with Google (same Firebase Auth as mobile). Firestore rules require authentication to read hazards, pulses, and road segments.

### Emulators

```bash
# Terminal 1 (repo root)
firebase emulators:start

# Terminal 2
cd command-center
VITE_USE_FIREBASE_EMULATORS=true npm run dev
```

## Build & deploy (Firebase Hosting)

```bash
cd command-center
npm run build
cd ..
firebase deploy --only hosting
```

Deploy **Functions** first so `getCommandCentreMetrics` is available:

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Full runbook: [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](../docs/setup/ACCOUNTS_AND_DEPLOYMENT.md) and [docs/COMMAND_CENTRE.md](../docs/COMMAND_CENTRE.md).
