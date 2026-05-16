# ExamAI Modular Production Refactor

This upgrade replaces the one huge `main.dart` with a stable modular Flutter structure.

## Copy these into your frontend folder

Replace:
- `frontend/lib`
- `frontend/pubspec.yaml`

with the `lib` folder and `pubspec.yaml` from this package.

## Run

```powershell
cd "C:\Users\HP ELITEBOOK 1040 G7\Documents\Ai Study Exam Assistant Build project\ai_exam_assistant\frontend"
flutter clean
flutter pub get
flutter run -d windows
```

## Build Android

```powershell
flutter build apk --release
```

## What changed

- Split app into folders: app, screens, widgets, services, models, theme, config, utils
- Fixed long-line Dart syntax problems
- Kept biometric auth, profile editing, AI tutor, upload, tasks, focus mode, quiz simulation, tools, responsive UI
- Added animated background, mascot movement, card hover, button bounce, stronger dashboard hero, cleaner navigation

This structure is much easier to maintain than one giant `main.dart`.
