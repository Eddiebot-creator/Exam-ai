
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,StudyMemory
from services.learning_engine import burnout,coach_message
router=APIRouter(prefix='/memory',tags=['AI Memory Graph / Burnout'])
@router.get('/{user_id}')
def get_memory(user_id:int,db:Session=Depends(get_db)):
    mem=db.query(StudyMemory).filter_by(user_id=user_id).first()
    if not mem: mem=StudyMemory(user_id=user_id,weak_topics=[],strong_topics=[],repeated_mistakes=[]); db.add(mem); db.commit(); db.refresh(mem)
    return {'weak_topics':mem.weak_topics or [],'strong_topics':mem.strong_topics or [],'repeated_mistakes':mem.repeated_mistakes or [],'burnout_risk':mem.burnout_risk,'preferred_style':mem.preferred_style,'coach_message':coach_message(mem.weak_topics or [])}
@router.get('/{user_id}/burnout')
def burnout_check(user_id:int,study_minutes_7d:int=300,failed_quizzes:int=0,late_sessions:int=0): return burnout(study_minutes_7d,failed_quizzes,late_sessions)
