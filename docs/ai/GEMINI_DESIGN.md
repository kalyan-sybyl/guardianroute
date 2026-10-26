# Gemini hazard analysis

## Flow

```text
Flutter → Storage (photo/audio) → Firestore hazardReports (PENDING)
       → Cloud Function analyzeHazardReport
       → Gemini (multimodal)
       → Validated JSON → hazards collection (+ dedupe)
       → hazardReports COMPLETED
       → Flutter result screen + map stream refresh
```

## Model

- **Production:** `gemini-2.0-flash` via `@google/generative-ai`
- **Secret:** `GEMINI_API_KEY` on Cloud Functions (never in Flutter)
- **Fallback:** If the key is missing or parsing fails, a safe MODERATE / OTHER analysis is stored

## Structured output

```json
{
  "hazardType": "POTHOLE",
  "severity": "HIGH",
  "confidence": 0.94,
  "description": "...",
  "recommendedAction": "..."
}
```

Validated with Zod in `functions/src/ai/hazardAnalysisSchema.ts`.

## Deduplication

Same `hazardType` within **50 m** and **48 h** → increment existing hazard `reportCount` instead of creating a duplicate.

## Local development

```bash
export GEMINI_API_KEY=your_key
firebase emulators:start
```

Without a key, the function still completes using the fallback analysis (useful for UI testing).
