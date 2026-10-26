# Google Maps — Phase 2

## Android Maps SDK key

Add to `mobile/android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_android_maps_sdk_key
```

Enable **Maps SDK for Android** in Google Cloud Console. Restrict the key to your app package and SHA-1.

## Places API (destination search)

Pass the same or a separate restricted key at build/run time:

```bash
flutter run --flavor development \
  --dart-define=FLAVOR=development \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

Enable **Places API** (legacy autocomplete used in Phase 2).

## iOS (secondary)

Set `GMSApiKey` in `ios/Runner/Info.plist` to your iOS Maps SDK key, or define `MAPS_API_KEY` in Xcode build settings.

## Map state (Riverpod)

| Provider | Role |
|----------|------|
| `mapCameraProvider` | Last camera position |
| `mapControllerHolderProvider` | `GoogleMapController` for animations |
| `userPositionProvider` | GPS stream via Geolocator |
| `mapHazardsProvider` | Firestore hazards + demo fallback |
| `mapMarkersProvider` | Hazard + destination markers |
| `selectedDestinationProvider` | Chosen place from search |
