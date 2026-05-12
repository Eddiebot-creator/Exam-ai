# AI Exam Assistant

MVP source for an AI study and exam assistant that targets Android and Windows with Flutter, backed by FastAPI.

## What is included

- Email/password registration and login API
- Notes upload API for PDF and text files
- Local SQLite development database, plus hosted PostgreSQL/Supabase support through `DATABASE_URL`
- AI summary, MCQ, and flashcard endpoints
- Offline fallback generation when `OPENAI_API_KEY` is not configured
- Flutter screens for onboarding, auth, dashboard, upload, AI modes, note chat, summaries, MCQs, flashcards, progress, subscriptions, and quiz mode
- Android, iOS, and Windows Flutter platform files

## Backend setup

```powershell
cd "C:\Users\HP ELITEBOOK 1040 G7\Documents\Ai Study Exam Assistant Build project\ai_exam_assistant\backend"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn main:app --host 127.0.0.1 --port 8010 --reload
```

Open the API docs at:

```text
http://127.0.0.1:8010/docs
```

To use real AI output, edit `.env` and add:

```text
OPENAI_API_KEY=your_key_here
```

For online hosting and cloud sync, set:

```text
DATABASE_URL=your_supabase_postgres_connection_string
```

If `DATABASE_URL` is set, the backend uses PostgreSQL. If it is empty, local SQLite is used.

## Flutter setup

Flutter was not installed on this machine when the project was scaffolded. Install Flutter first, then run:

```powershell
cd "C:\Users\HP ELITEBOOK 1040 G7\Documents\Ai Study Exam Assistant Build project\ai_exam_assistant"
cd frontend
flutter create --platforms=android,ios,windows --no-overwrite .
flutter pub get
flutter run -d windows
```

For Android emulator builds, Android uses `10.0.2.2` to reach the host machine:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8010
```

For real phones, build with the hosted API URL:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Backend updates deployed online update all installed apps immediately. Flutter UI updates require a new APK, Play Store release, or TestFlight/App Store release.

## Release builds

```powershell
cd frontend
flutter build apk --release
flutter build windows
```

iOS builds require macOS and Xcode:

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://your-api.example.com
```

The Android APK will be under `frontend\build\app\outputs\flutter-apk`.
The Windows app will be under `frontend\build\windows\x64\runner\Release`.
