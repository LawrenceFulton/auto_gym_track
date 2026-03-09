# Auto Gym Track

Voice-first workout logging POC built with Flutter.

## What this POC currently does
- Prompts for an OpenRouter API key on first launch (bring your own key).
- Saves the key on-device using secure storage and reuses it on future launches.
- Starts a workout session from a setup screen.
- Uses built-in device speech recognition through `speech_to_text` (with a mock fallback if recognition is unavailable).
- Runs extraction state machine (`recording -> transcribing -> extracting -> reviewing -> saved`).
- Validates parsed workout JSON into typed models.
- Saves parsed sets into SQLite.
- Shows set history for the active session.

## Platform notes
- Android microphone permission is configured in `android/app/src/main/AndroidManifest.xml`.
- iOS microphone and speech usage descriptions are configured in `ios/Runner/Info.plist`.

## Project layout
- `lib/src/application/`: flow orchestration and JSON validation
- `lib/src/data/`: SQLite database/repository and API service stubs
- `lib/src/domain/`: core entities
- `lib/src/ui/`: setup/active/review/history screens

## Next integrations
- Add a settings action to rotate/clear the saved OpenRouter key.
- Improve offline/on-device STT handling (locale selection, explicit offline preference, and richer error states).
- Add exercise media lookup and display in active workout UI.

## Run
```bash
flutter pub get
flutter run
```

## Test
```bash
flutter test
```
