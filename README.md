# GuardianRoute

**Navigate safer. Arrive safer.**

AI-powered road-safety intelligence for boda boda riders and motorists — built with Flutter, Firebase, Gemini, and Google Maps for the Google/GDG hackathon in Uganda.

## Repository layout

```text
guardianroute/
├── mobile/           # Flutter app (Android primary)
├── functions/        # Cloud Functions (TypeScript)
├── firebase/         # Security rules and indexes
├── command-center/   # Web command centre (Phase 9)
├── docs/             # Architecture and runbooks
└── scripts/          # Tooling helpers
```

## Prerequisites

- Flutter 3.x (stable)
- Node.js 20+ (Cloud Functions)
- Android Studio / SDK (API 24+)
- Firebase CLI (`npm install -g firebase-tools`) — optional for emulators

## Firebase setup (required before device testing)

**Full checklist (signup, API keys, deploy):** [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](docs/setup/ACCOUNTS_AND_DEPLOYMENT.md)

Short version:

1. Create a Firebase project in the [Firebase console](https://console.firebase.google.com/) (Blaze plan for deployed Functions).
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. From `mobile/`: `flutterfire configure`
4. Place `mobile/android/app/google-services.json` (from Firebase or FlutterFire).
5. Enable **Authentication** (Google + Anonymous), **Firestore**, **Storage**, **Functions**, **App Check**, **Crashlytics**, **Analytics**, **Remote Config**.
6. Copy `functions/.env.example` → `functions/.env` with `GEMINI_API_KEY` and `GOOGLE_MAPS_API_KEY` before `firebase deploy --only functions`.

## Local development with emulators

```bash
# From repo root (after firebase login)
firebase emulators:start --import=./firebase/emulator-data --export-on-exit

# Android emulator → host machine
cd mobile
flutter run --flavor development --dart-define=USE_FIREBASE_EMULATORS=true
```

Emulator ports (default): Auth `9099`, Firestore `8080`, Functions `5001`, Storage `9199`.

## Run the app

```bash
cd mobile
flutter pub get
flutter analyze
flutter test

# Development flavor (default entry: lib/main.dart)
flutter run --flavor development --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_api_key

# Demo / production
flutter run --flavor demo --dart-define=FLAVOR=demo \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_api_key
flutter run --flavor production --dart-define=FLAVOR=production
```

### Google Maps (Phase 2)

Add to `mobile/android/local.properties`:

```properties
MAPS_API_KEY=your_android_maps_sdk_key
```

See `docs/architecture/GOOGLE_MAPS.md` for iOS and Places setup.

## Cloud Functions

```bash
cd functions
npm install
export GEMINI_API_KEY=your_key   # optional; fallback analysis if unset
npm run build
npm test
```

Hazard reports trigger `analyzeHazardReport` when a `hazardReports` document is created with `status: PENDING`. See `docs/ai/GEMINI_DESIGN.md`.

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/setup/ACCOUNTS_AND_DEPLOYMENT.md](docs/setup/ACCOUNTS_AND_DEPLOYMENT.md) | Where to sign up, keys, deploy rules & Functions |
| [docs/COMMAND_CENTRE.md](docs/COMMAND_CENTRE.md) | Web dashboard + Hosting |
| [command-center/README.md](command-center/README.md) | Run / build the Command Centre |
| [docs/firebase/EMULATORS.md](docs/firebase/EMULATORS.md) | Local Firebase emulators |
| [docs/architecture/GOOGLE_MAPS.md](docs/architecture/GOOGLE_MAPS.md) | Maps / Places keys |
| [docs/architecture/SYSTEM_ARCHITECTURE.md](docs/architecture/SYSTEM_ARCHITECTURE.md) | System overview |
| `GUARDIANROUTE_MASTER_PROMPT.md` | Product and engineering requirements |

## Phase status

- **Phase 0** — Architecture (complete)
- **Phase 1** — Flutter foundation + Firebase wiring (complete)
- **Phase 2** — Google Maps, location, hazards on map (complete)
- **Phase 3** — Hazard reporting + Gemini (complete)
- **Phase 4** — Sensor intelligence (complete)
- **Phase 5** — Guardian Pulse™ (complete)
- **Phase 6** — Road risk engine (complete)
- **Phase 7** — Safe routing (complete)
- **Phase 8** — Active navigation (complete)
- **Phase 9** — Command Centre web (complete)
