# ExamAI Deployment

## What Updates Automatically

Hosted backend updates reach every installed app immediately because all apps call the same online API.

This includes:

- AI prompts and output behavior
- summaries, quizzes, flashcards, chat, study planner, and exam prediction
- premium/free limits
- cloud account data
- teacher/class data
- bug fixes inside API routes

Mobile UI updates still require a new Android/iOS app build and release through APK sharing, Google Play, or TestFlight/App Store.

## Recommended Production Stack

- Backend: Render web service
- Database: Supabase PostgreSQL
- Android distribution: Google Play internal testing, then production
- iOS distribution: TestFlight, then App Store
- Web preview, optional: Flutter Web

The backend can be deployed to Render or Railway as a FastAPI service.

### Render

1. Push this project to GitHub.
2. Create a Supabase project.
3. In Supabase, copy the PostgreSQL connection string. Use the pooled connection string if Supabase gives you one.
4. In Render, create a new Blueprint and select this repo.
5. Use the root `render.yaml` or `backend/render.yaml`.
6. Add these Render environment variables:

```text
OPENAI_API_KEY=your_openai_key
DATABASE_URL=your_supabase_postgres_connection_string
```

7. Deploy and copy the HTTPS service URL.
8. Open `/docs` on the deployed URL.

Build command:

```bash
pip install -r requirements.txt
```

Start command:

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

Production database behavior:

- If `DATABASE_URL` is set, the backend uses PostgreSQL/Supabase.
- If `DATABASE_URL` is empty, the backend uses local SQLite at `DATABASE_PATH`.

## Mobile Builds

Use the deployed HTTPS backend URL when building real Android and iOS apps:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
flutter build ios --release --dart-define=API_BASE_URL=https://your-api.example.com
```

After this, the installed app can be used anywhere as long as the backend URL stays online.

## Update Workflow

For backend updates:

```bash
git add .
git commit -m "Update backend"
git push
```

Render redeploys automatically after the push. Users do not need to reinstall the app.

For Flutter UI updates:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Upload the app bundle to Google Play. For iOS, build and upload from macOS/Xcode/TestFlight.
