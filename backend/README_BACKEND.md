
# ExamAI Complete Backend Engine

Includes authentication, note upload, summaries, flashcards, MCQs, quiz engine, progress tracking, AI tutor, profile system, biometric hooks, XP/streaks, weak-topic tracking, burnout detection, school mode, voice tutor, study rooms, camera/OCR, full AI memory graph, wellness systems, and exam prediction engine.

## Run locally
Use Python 3.12.

```powershell
cd backend
py -3.12 -m venv .venv
.\.venv\Scriptsctivate
pip install -r requirements.txt
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8010
```

Open http://127.0.0.1:8010/docs

## Render
Root Directory: backend
Build Command: pip install -r requirements.txt
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
