# AGENT.md - Auto Gym Track POC Blueprint

## Goal
Build a Flutter proof of concept where a user logs gym sets by voice, with local speech-to-text, LLM-based structuring via OpenRouter, and SQLite history tracking.

## Core User Story
- As a user, I press a record button and speak a set, for example:
  - "Bench press, three sets of eight at eighty-five kilos." or "I did squats, 5 reps at 100 kg."
- The app transcribes speech locally to raw text.
- The app sends raw text to OpenRouter with a strict extraction prompt.
- The model returns structured JSON for exercise, sets, reps, and weight.
- The app stores results in SQLite so I can view history/progress.
- During a workout, the app shows the current exercise name.
- Later, the app can show a photo/GIF for that exercise.

## End-to-End Flow (MVP)
1. User selects or creates a workout setup/template.
2. User starts workout session.
3. User taps `Record Set`.
4. App captures audio and runs local speech-to-text.
5. App sends transcript text to OpenRouter extraction endpoint.
6. App validates and normalizes JSON response.
7. User confirms/edit parsed set (optional but recommended in MVP).
8. App saves set entry to SQLite.
9. UI updates current exercise progress and history.

## Architecture (Suggested)
- `ui` layer: widgets/screens for setup, recording, review, history.
- `application` layer: orchestrates capture -> transcribe -> extract -> save.
- `domain` layer: entities/value objects (`Exercise`, `SetEntry`, `WorkoutSession`).
- `data` layer: local DB (`sqflite`), OpenRouter client, media metadata source.

## Feature Breakdown

### 1) Audio Capture
- Add a record button and state machine:
  - `idle -> recording -> transcribing -> extracting -> reviewing -> saved/error`
- Save short audio clips per set event if needed for debugging/retry.

### 2) Local Speech-to-Text
- Must be on-device/local for transcription.
- Candidate implementation: Flutter plugin that supports offline STT.
- Output: raw transcript string and confidence metadata (if available).

### 3) OpenRouter Data Extraction
- Send only transcript text (and maybe current exercise context).
- Use a strict system prompt and response schema.
- Expect JSON only, no prose.

#### Example target JSON
```json
{
  "exercise_name": "Bench Press",
  "sets": [
    { "set_number": 1, "reps": 8, "weight": 85, "unit": "kg" },
    { "set_number": 2, "reps": 8, "weight": 85, "unit": "kg" },
    { "set_number": 3, "reps": 8, "weight": 85, "unit": "kg" }
  ],
  "notes": null,
  "confidence": 0.91
}
```

#### Extraction system prompt (starter)
```text
You convert gym workout transcripts into strict JSON.
Return valid JSON only.
Extract:
- exercise_name (string)
- sets (array of objects with set_number, reps, weight, unit)
- notes (string|null)
- confidence (0.0-1.0)
If uncertain, use best estimate and lower confidence.
Never include markdown or explanations.
```

### 4) Logging + SQLite Storage
- Use `sqflite` for local persistence.
- Tables (minimum):
  - `workout_sessions`
  - `exercise_entries`
  - `set_entries`
- Keep timestamps for analytics and trend charts.

### 5) Setup + In-Workout Exercise Display
- Pre-workout: user builds routine/template with ordered exercises.
- In-workout: show current exercise prominently.
- Future: attach media URL/asset key to exercise and render photo/GIF.

## Proposed Data Model (MVP)
- `WorkoutSession`: id, started_at, ended_at, template_name
- `ExerciseEntry`: id, session_id, exercise_name, order_index, media_ref
- `SetEntry`: id, exercise_entry_id, set_number, reps, weight, unit, source_transcript, created_at

## Tool Call Concept for Structured Insert (Optional)
If using model tool-calling semantics, define one function-like contract:
- `log_workout_set(exercise_name, sets[], notes, confidence, transcript)`
- App validates payload and persists to SQLite.

This is optional for POC. Direct JSON response + app-side validation is enough.

## MVP Milestones

### Milestone 1: Vertical Slice
- Record audio
- Local transcription
- Mock parser output to UI
- Save to SQLite

### Milestone 2: OpenRouter Integration
- Real extraction API call
- JSON validation + error handling
- Confirmation screen before save

### Milestone 3: Workout Setup + Active Session UI
- Routine builder with exercise order
- Active workout screen with current exercise indicator
- Set history list for current session

### Milestone 4: Exercise Media (Phase 2)
- Add `media_ref` to exercises
- Display static image or GIF on active exercise card

## Acceptance Criteria (POC)
- User can record one spoken set and see transcript.
- Transcript is parsed into valid structured JSON via OpenRouter.
- Parsed data is persisted in SQLite and visible in history.
- User can create a simple routine and see current exercise while training.
- At least one exercise can display media (placeholder acceptable for POC).

## Risks + Mitigations
- Offline STT quality varies by device/language:
  - Add manual edit step before save.
- LLM extraction may return malformed JSON:
  - Enforce schema validation and retry with correction prompt.
- Unit ambiguity (lbs vs kg):
  - Default from user preference and allow correction.

## Next Build Tasks (Actionable)
- [x] Add dependencies: local STT plugin, `sqflite`, `path_provider`, HTTP client.
- [x] Create domain entities and JSON schema validator.
- [x] Build record/transcribe/extract state machine.
- [x] Implement OpenRouter client with strict prompt and timeout/retry (scaffolded client).
- [x] Implement SQLite repositories and migrations.
- [x] Build screens: setup, active workout, confirm parsed set, history.
- [ ] Add sample exercise media mapping and renderer.
- [x] Add minimal tests for parser validation and DB insert/query.
