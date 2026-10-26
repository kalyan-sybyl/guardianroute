# Hazard proximity warnings (Phase 8)

During **active navigation**, the app tracks GPS and compares the rider position to active hazards.

## Eligibility

Warn when:

- Hazard status is not `resolved` / `stale`
- Severity is **high** or **critical**, or **moderate** with confidence ≥ 0.7
- Distance to rider ≤ `hazard_warning_distance_meters` (Remote Config, default **300**)
- Hazard is within **120 m** of the selected route polyline

## UX

- **Visual:** red error-container banner — danger ahead, type, distance, “REDUCE SPEED”
- **Audio:** `flutter_tts` (toggle in Profile → Navigation voice warnings)
- Each hazard triggers at most **one** voice alert per navigation session
- Analytics: `navigation_started`, `hazard_warning_displayed`

## Remaining distance

Estimated along the route polyline from the closest segment to the destination endpoint, used for ETA scaling from the planned route duration.
