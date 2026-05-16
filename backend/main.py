
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routes import auth,profile,notes,flashcards,quiz,progress,ai,memory,wellness,exams,voice,camera,study_rooms,school,intelligence,offline_sync,social_study,autonomous
app=FastAPI(title='ExamAI Complete Backend Engine',version='1.0.0')
app.add_middleware(CORSMiddleware,allow_origins=['*'],allow_credentials=True,allow_methods=['*'],allow_headers=['*'])
@app.on_event('startup')
def startup(): init_db()
@app.get('/')
def root(): return {'status':'ok','app':'ExamAI Complete Backend Engine','modules':['authentication','note upload','summaries','flashcards','MCQs','quiz engine','progress tracking','AI tutor','profile system','biometric hooks','XP/streaks','weak-topic tracking','burnout detection','school mode','voice tutor','study rooms','camera/OCR','AI memory graph','wellness','exam prediction']}
for r in [auth.router,profile.router,notes.router,flashcards.router,quiz.router,progress.router,ai.router,memory.router,wellness.router,exams.router,voice.router,camera.router,study_rooms.router,school.router,intelligence.router,offline_sync.router,social_study.router,autonomous.router]: app.include_router(r)
