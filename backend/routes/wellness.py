
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,WellnessCheck
from services.learning_engine import burnout
router=APIRouter(prefix='/wellness',tags=['Wellness'])
@router.post('/{user_id}/check-in')
def check_in(user_id:int,p:dict,db:Session=Depends(get_db)):
    db.add(WellnessCheck(user_id=user_id,mood=p.get('mood','okay'),stress=int(p.get('stress',3)),note=p.get('note',''))); db.commit(); return {'saved':True,'burnout':burnout(int(p.get('study_minutes_7d',300)),int(p.get('failed_quizzes',0)),int(p.get('late_sessions',0)))}
