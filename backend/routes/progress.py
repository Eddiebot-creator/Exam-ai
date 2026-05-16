
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,ProgressEvent,QuizAttempt,StudyMemory,User
router=APIRouter(prefix='/progress',tags=['Progress / XP / Streaks'])
@router.get('/{user_id}')
def progress(user_id:int,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first(); attempts=db.query(QuizAttempt).filter_by(user_id=user_id).all(); events=db.query(ProgressEvent).filter_by(user_id=user_id).all(); mem=db.query(StudyMemory).filter_by(user_id=user_id).first(); total_score=sum(a.score for a in attempts); total_q=sum(a.total for a in attempts) or 1
    return {'user_id':user_id,'xp':u.xp if u else 0,'level':u.level if u else 1,'streak_days':u.streak_days if u else 0,'study_seconds':sum(e.seconds for e in events),'average_score':round(total_score/total_q*100),'weak_topics':mem.weak_topics if mem else []}
@router.post('/study-time')
def study_time(p:dict,db:Session=Depends(get_db)):
    user_id=int(p.get('user_id',1)); seconds=int(p.get('seconds',0)); xp=max(1,seconds//60); db.add(ProgressEvent(user_id=user_id,activity=p.get('activity','study'),note_id=p.get('note_id'),seconds=seconds,xp=xp)); u=db.query(User).filter_by(id=user_id).first()
    if u: u.xp+=xp; u.level=max(1,u.xp//200+1); u.streak_days=max(u.streak_days,1); db.add(u)
    db.commit(); return {'ok':True,'xp_added':xp}
