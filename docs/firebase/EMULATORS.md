# Firebase Emulator Suite

## Start emulators

From the repository root:

```bash
firebase emulators:start
```

Default ports (see `firebase.json`):

| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Storage | 9199 |
| Emulator UI | 4000 |

## Flutter app

Android emulator uses `10.0.2.2` as the host loopback:

```bash
cd mobile
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Physical device: use your machine's LAN IP with `--dart-define=FIREBASE_EMULATOR_HOST=192.168.x.x`.

## Functions

```bash
cd functions
npm install
npm run build
```

Deploy is not required for emulator testing when the Functions emulator loads compiled `lib/`.
