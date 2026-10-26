# Accounts, API keys, and deployment

End-to-end checklist for standing up **GuardianRoute** on your own Firebase and Google Cloud project — before Command Centre (Phase 9) or a hackathon demo on real backends.

**Time:** roughly 1–2 hours the first time if you already have Flutter and Node installed.

---

## What you need (summary)

| What | Where you sign up | Used for |
|------|-------------------|----------|
| Google account | [google.com](https://accounts.google.com) | Everything below |
| Firebase project | [Firebase console](https://console.firebase.google.com) | Auth, Firestore, Storage, Functions, Analytics, Crashlytics, Remote Config, App Check |
| Google Cloud project | Same as Firebase (linked automatically) | Maps, Places, Directions APIs, billing |
| Gemini API key | [Google AI Studio](https://aistudio.google.com/apikey) | Cloud Function hazard analysis (server only) |
| Maps Platform keys | [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials) | Android map, Places search, Directions (server) |
| Firebase CLI | `npm install -g firebase-tools` | Emulators, deploy rules/functions |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` | `firebase_options.dart`, `google-services.json` |

**Never commit:** `google-services.json`, `GoogleService-Info.plist`, `functions/.env`, or any API key files. They are gitignored.

---

## 1. Create a Firebase project

1. Open [Firebase console](https://console.firebase.google.com) → **Add project**.
2. Pick a name (e.g. `guardianroute-dev`). Note the **Project ID** (lowercase, no spaces).
3. Enable or skip Google Analytics (recommended for `navigation_started`, hazard events).
4. Wait for the project to finish provisioning.

### Upgrade to Blaze (pay-as-you-go)

Cloud Functions (2nd gen), scheduled jobs, and outbound Google API calls from Functions require the **Blaze** plan:

1. Firebase console → **Upgrade** (bottom of left nav).
2. Link a billing account. Stay within [Firebase/Google Cloud free tiers](https://firebase.google.com/pricing) where possible; hackathon traffic is usually small.

Without Blaze you can still use **local emulators** for most development.

---

## 2. Enable Firebase products

In Firebase console, enable or confirm:

| Product | Console path | GuardianRoute usage |
|---------|----------------|---------------------|
| **Authentication** | Build → Authentication → Get started | Anonymous + Google sign-in |
| **Firestore** | Build → Firestore → Create database | Hazards, reports, road segments, pulses |
| **Storage** | Build → Storage → Get started | Hazard photos / voice |
| **Functions** | Build → Functions | Callables, triggers, schedulers |
| **App Check** | Build → App Check | Protect backend (debug token in dev) |
| **Crashlytics** | Build → Crashlytics | Crashes (release builds) |
| **Remote Config** | Build → Remote Config | Warning distance, sensor thresholds |

### Firestore region

Choose a region close to users (e.g. **`europe-west`** or **`africa-south1`** if available). Cloud Functions in this repo default to **`europe-west1`** (`functions/src/index.ts`). Prefer keeping Firestore and Functions in the same broad area when possible.

### Authentication providers

1. **Authentication → Sign-in method**
2. Enable **Anonymous**.
3. Enable **Google** — set support email; Firebase creates OAuth clients in Google Cloud.
4. **Android Google Sign-In:** register your app SHA-1 (see [§5 Android app](#5-register-the-flutter-app-android)).

---

## 3. Register the Flutter app (Android)

1. Firebase console → **Project settings** (gear) → **Your apps** → **Add app** → **Android**.
2. **Package name:** `com.guardianroute.guardianroute` (must match `mobile/android/app/build.gradle.kts`).
3. Download **`google-services.json`** → place at:

   `mobile/android/app/google-services.json`

4. (Optional) Add the same app in FlutterFire (recommended):

   ```bash
   cd mobile
   flutterfire configure
   ```

   Select your Firebase project and Android (and iOS if needed). This refreshes `lib/firebase_options.dart` with real API keys and app IDs.

5. Update repo root **`.firebaserc`** so `default` is your project ID:

   ```json
   {
     "projects": {
       "default": "your-project-id"
     }
   }
   ```

---

## 4. Google Cloud APIs and Maps keys

Firebase projects share a **Google Cloud project** (Console → Project settings → **Project ID**). Open [Google Cloud Console](https://console.cloud.google.com) with that project selected.

### Enable APIs

**APIs & Services → Library** — enable:

| API | Needed for |
|-----|------------|
| **Maps SDK for Android** | Map tiles in the Flutter app |
| **Places API** | Destination search (`GOOGLE_MAPS_API_KEY` in Flutter) |
| **Directions API** | `planSafeRoutes` on Cloud Functions |
| **Geocoding API** | Optional; helpful for Places/details |

### Create API keys (recommended: separate keys)

**APIs & Services → Credentials → Create credentials → API key**

1. **Android Maps SDK key**
   - Restrict → **Android apps** → package `com.guardianroute.guardianroute` + **SHA-1** (debug and/or release).
   - Put in `mobile/android/local.properties` (file is gitignored):

     ```properties
     MAPS_API_KEY=AIza...
     ```

2. **Places key (client)**
   - Restrict → **Android apps** (same package + SHA-1) or IP for local dev.
   - Pass at run time (not committed):

     ```bash
     flutter run --flavor development \
       --dart-define=FLAVOR=development \
       --dart-define=GOOGLE_MAPS_API_KEY=AIza...
     ```

3. **Directions / server key**
   - Restrict → **API restrictions** → Directions API only.
   - Restrict → **Application restrictions** → none (server) or IP of Cloud Functions if you lock it down later.
   - Store only in **`functions/.env`** (see [§7](#7-cloud-functions-secrets-and-env)) — **not** in the Flutter app.

See also: [docs/architecture/GOOGLE_MAPS.md](../architecture/GOOGLE_MAPS.md).

### Android debug SHA-1 (Google Sign-In + Maps restriction)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Add the SHA-1 in Firebase **Project settings → Your apps → Android app**.

---

## 5. Gemini API key (hazard AI)

1. Go to [Google AI Studio → API keys](https://aistudio.google.com/apikey).
2. Create a key (Google AI / Gemini Developer API).
3. Use it **only on the server** (`functions/.env` as `GEMINI_API_KEY`). Do not put it in Flutter or commit it.

If the key is missing, `analyzeHazardReport` still completes with a safe fallback analysis (see [docs/ai/GEMINI_DESIGN.md](../ai/GEMINI_DESIGN.md)).

---

## 6. App Check (development vs production)

The app activates **debug** App Check providers in debug builds (`mobile/lib/app/bootstrap.dart`).

1. Firebase console → **App Check** → register your Android app.
2. For local/debug builds: **Manage debug tokens** → add the token printed in logcat when the app starts (or from the App Check debug provider flow).
3. For release: use **Play Integrity** (Android) and enforce App Check on Callable Functions / Firestore when you are ready for production.

Until debug tokens are registered, some backend calls may fail against **production** Firebase while emulators work fine.

---

## 7. Cloud Functions: secrets and `.env`

Function code reads:

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Multimodal hazard analysis |
| `GOOGLE_MAPS_API_KEY` or `DIRECTIONS_API_KEY` | Live route alternatives in `planSafeRoutes` |

### Local emulators

```bash
cd functions
cp .env.example .env
# Edit .env with your keys
npm install
npm run build

# From repo root
firebase emulators:start
```

Exporting in the shell also works for emulator sessions:

```bash
export GEMINI_API_KEY=...
export GOOGLE_MAPS_API_KEY=...
firebase emulators:start
```

### Deploy to Firebase

1. Create **`functions/.env`** from the example (gitignored):

   ```bash
   cd functions
   cp .env.example .env
   ```

2. Edit `.env`:

   ```env
   GEMINI_API_KEY=your_gemini_key
   GOOGLE_MAPS_API_KEY=your_directions_restricted_key
   ```

   Firebase CLI loads `functions/.env` when you deploy (see [Firebase environment configuration](https://firebase.google.com/docs/functions/config-env)).

3. For stronger production hygiene, prefer **Secret Manager**:

   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   firebase functions:secrets:set GOOGLE_MAPS_API_KEY
   ```

   Today’s function exports use `process.env` without declaring `secrets: [...]` on each function. If secrets do not appear at runtime after deploy, either rely on `.env` for the hackathon or add `secrets: ["GEMINI_API_KEY", "GOOGLE_MAPS_API_KEY"]` to the relevant `onCall` / `onDocumentCreated` options in `functions/src/`.

### Functions region

All deployed functions use **`europe-west1`**. Callable functions from Flutter use `FirebaseFunctions.instance` (default region). If you see `NOT_FOUND` when calling `planSafeRoutes` or `ensureUserProfile` against production, set the client region to match, e.g. in bootstrap:

`FirebaseFunctions.instanceFor(region: 'europe-west1')`

(and use that instance in repositories). Emulator mode is unaffected.

---

## 8. Deploy checklist (repo root)

Prerequisites:

```bash
npm install -g firebase-tools
firebase login
firebase use your-project-id   # or firebase use --add
```

### One-time: rules and indexes

```bash
# From repository root
firebase deploy --only firestore:rules,firestore:indexes,storage
```

- Rules: `firebase/firestore.rules`, `firebase/storage.rules`
- Indexes: `firebase/firestore.indexes.json` (required for compound queries)

If Firestore logs an index URL in the console, open it or add the index to `firestore.indexes.json` and redeploy indexes.

### Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
npm test
cd ..
firebase deploy --only functions
```

`firebase.json` runs `npm run build` in `functions/` before deploy (`predeploy`).

### Scheduled functions

These require Blaze and Cloud Scheduler (usually auto-enabled on first deploy):

- `detectGuardianPulse` — periodic Guardian Pulse detection
- `calculateRoadRiskScheduled` — road risk recalculation

Check **Google Cloud Console → Cloud Scheduler** after deploy if pulses/risk never update in production.

---

## 9. Run the mobile app against production

```bash
cd mobile
flutter pub get
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key
```

Do **not** set `USE_FIREBASE_EMULATORS=true` when testing the live backend.

Ensure `google-services.json` and (if used) `flutterfire configure` output match the same Firebase project you deployed to.

---

## 10. Run against emulators only (no deploy)

No Blaze or API keys strictly required for a minimal path (Gemini/Directions fallbacks still apply).

```bash
# Terminal 1 — repo root
firebase emulators:start

# Terminal 2
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=GOOGLE_MAPS_API_KEY=your_places_key_if_testing_search
```

Details: [docs/firebase/EMULATORS.md](../firebase/EMULATORS.md).

Physical device: add `--dart-define=FIREBASE_EMULATOR_HOST=192.168.x.x` (your machine’s LAN IP).

---

## 11. Verification smoke test

| Step | Expect |
|------|--------|
| Sign in (anonymous or Google) | Lands on map |
| Callable `ping` | Auth + Functions reachable |
| Report hazard with photo | `hazardReports` → `analyzeHazardReport` → hazard on map |
| Plan route | `planSafeRoutes` returns 3 options (demo polylines if Directions key missing) |
| Start navigation | GPS + proximity banner near demo hazards |

**Functions logs:** Firebase console → Functions → Logs, or:

```bash
firebase functions:log
```

---

## 12. Quick reference — files you touch locally

| File | Action |
|------|--------|
| `.firebaserc` | Set `default` project ID |
| `mobile/android/app/google-services.json` | Download from Firebase |
| `mobile/lib/firebase_options.dart` | Generate via `flutterfire configure` |
| `mobile/android/local.properties` | `MAPS_API_KEY=...` |
| `functions/.env` | `GEMINI_API_KEY`, `GOOGLE_MAPS_API_KEY` |
| Run / CI | `--dart-define=GOOGLE_MAPS_API_KEY=...` |

---

## 13. Related docs

- [README.md](../../README.md) — run commands and layout
- [docs/architecture/GOOGLE_MAPS.md](../architecture/GOOGLE_MAPS.md) — Maps vs Places keys
- [docs/firebase/EMULATORS.md](../firebase/EMULATORS.md) — emulator ports and Flutter flags
- [docs/ai/GEMINI_DESIGN.md](../ai/GEMINI_DESIGN.md) — hazard analysis pipeline
- [docs/algorithms/ROUTE_SCORING.md](../algorithms/ROUTE_SCORING.md) — Directions API on Functions

---

## Troubleshooting

| Symptom | Likely fix |
|---------|------------|
| Google Sign-In fails on device | Add SHA-1 to Firebase Android app; enable Google provider |
| Map blank / gray tiles | Enable Maps SDK for Android; check `MAPS_API_KEY` in `local.properties` |
| Destination search error | Pass `GOOGLE_MAPS_API_KEY`; enable Places API |
| `planSafeRoutes` always demo routes | Set `GOOGLE_MAPS_API_KEY` in `functions/.env` and redeploy; enable Directions API |
| Hazard stays PENDING | Deploy functions; check `GEMINI_API_KEY` and function logs |
| Callable `NOT_FOUND` | Deploy functions; match region `europe-west1` on client |
| Permission denied on Firestore | Deploy `firestore.rules`; user must be signed in |
| App Check errors on production | Register debug token or use release build with Play Integrity |

## 14. Command Centre (web + Hosting)

1. Firebase console → Project settings → **Add app** → **Web** → copy config into `command-center/.env` (see `command-center/.env.example`).
2. Enable **Maps JavaScript API** for `VITE_GOOGLE_MAPS_API_KEY`.
3. Authentication → **Authorized domains** — add `localhost` and your `*.web.app` / custom domain after deploy.
4. Build and deploy:

   ```bash
   cd command-center
   cp .env.example .env   # fill values
   npm install
   npm run build
   cd ..
   firebase deploy --only hosting
   ```

5. Ensure `getCommandCentreMetrics` is deployed (`firebase deploy --only functions`) so sensor and report counts work.

Details: [docs/COMMAND_CENTRE.md](../COMMAND_CENTRE.md).
