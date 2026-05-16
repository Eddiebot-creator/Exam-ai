
from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy.orm import Session
from database import get_db,User,StudyMemory,QuizAttempt,Note
from services.learning_engine import readiness,days_until,coach_message
router=APIRouter(prefix='/exams',tags=['Exam Prediction'])
@router.post('/{user_id}/setup')
def setup(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    u.exam_course=p.get('course',''); u.exam_date=p.get('exam_date',''); u.target_score=int(p.get('target_score',80)); db.commit(); db.refresh(u); return {'ok':True,'course':u.exam_course,'exam_date':u.exam_date,'target_score':u.target_score}
@router.get('/{user_id}/prediction')
def prediction(user_id:int,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first(); attempts=db.query(QuizAttempt).filter_by(user_id=user_id).all(); mem=db.query(StudyMemory).filter_by(user_id=user_id).first(); notes=db.query(Note).filter_by(user_id=user_id).all(); avg=round(sum(a.score for a in attempts)/max(1,sum(a.total for a in attempts))*100) if attempts else 74; weak=mem.weak_topics if mem and mem.weak_topics else ['Recursion']; topics=[]
    for n in notes: topics+=n.topics or []
    days=days_until(u.exam_date if u else ''); return {'course':u.exam_course if u else 'Course','days_left':days,'readiness':readiness(avg,len(weak),u.streak_days if u else 0,days),'likely_topics':list(dict.fromkeys(weak+topics))[:8],'recommendation':coach_message(weak)}
