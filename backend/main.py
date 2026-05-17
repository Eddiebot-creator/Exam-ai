
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import DATABASE_URL, engine, init_db
from routes import auth,profile,notes,flashcards,quiz,progress,ai,memory,wellness,exams,voice,camera,study_rooms,school,intelligence,offline_sync,social_study,autonomous,institution
app=FastAPI(title='ExamAI Complete Backend Engine',version='1.0.0')
raw_origins=os.getenv('ALLOWED_ORIGINS','')
allowed_origins=[origin.strip() for origin in raw_origins.split(',') if origin.strip()]
app.add_middleware(CORSMiddleware,allow_origins=allowed_origins or ['*'],allow_credentials=bool(allowed_origins),allow_methods=['*'],allow_headers=['*'])
@app.on_event('startup')
def startup(): init_db()
@app.get('/')
def root(): return {'status':'ok','app':'ExamAI Complete Backend Engine','modules':['authentication','note upload','summaries','flashcards','MCQs','quiz engine','progress tracking','AI tutor','profile system','biometric hooks','XP/streaks','weak-topic tracking','burnout detection','school mode','voice tutor','study rooms','camera/OCR','AI memory graph','wellness','exam prediction']}
@app.get('/health/deep')
def deep_health():
    checks={'database':'unknown','gemini':'configured' if os.getenv('GEMINI_API_KEY') else 'not_configured','openai':'configured' if os.getenv('OPENAI_API_KEY') else 'not_configured','storage':'ok'}
    try:
        with engine.connect() as conn:
            conn.exec_driver_sql('SELECT 1')
        checks['database']='ok'
    except Exception as exc:
        checks['database']=f'error: {exc.__class__.__name__}'
    checks['database_driver']='postgresql+psycopg' if DATABASE_URL.startswith('postgresql+psycopg') else 'sqlite' if DATABASE_URL.startswith('sqlite') else 'other'
    healthy=checks['database']=='ok'
    return {'status':'ok' if healthy else 'degraded','checks':checks}
for r in [auth.router,profile.router,notes.router,flashcards.router,quiz.router,progress.router,ai.router,memory.router,wellness.router,exams.router,voice.router,camera.router,study_rooms.router,school.router,intelligence.router,offline_sync.router,social_study.router,autonomous.router,institution.router]: app.include_router(r)
