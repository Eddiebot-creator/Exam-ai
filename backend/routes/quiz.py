
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,Mcq,QuizAttempt,StudyMemory,User,Achievement
from services.learning_engine import coach_message
router=APIRouter(prefix='/quiz',tags=['Quiz Engine'])
@router.get('/start/{user_id}')
def start(user_id:int,mode:str='practice',limit:int=10,db:Session=Depends(get_db)):
    qs=db.query(Mcq).filter_by(user_id=user_id).limit(limit).all(); return {'mode':mode,'timer_seconds':900 if mode in ['mock','exam'] else 0,'questions':[{'id':q.id,'topic':q.topic,'question':q.question,'options':q.options} for q in qs]}
@router.post('/submit/{user_id}')
def submit(user_id:int,p:dict,db:Session=Depends(get_db)):
    score=0; weak=[]; review=[]
    for a in p.get('answers',[]):
        q=db.query(Mcq).filter_by(id=a.get('question_id'),user_id=user_id).first()
        if not q: continue
        correct=int(a.get('selected_index',-1))==q.answer_index; score+=1 if correct else 0
        if not correct: weak.append(q.topic)
        review.append({'question_id':q.id,'correct':correct,'answer_index':q.answer_index,'explanation':q.explanation,'topic':q.topic})
    total=max(1,len(review)); db.add(QuizAttempt(user_id=user_id,mode=p.get('mode','practice'),score=score,total=total,weak_topics=list(set(weak)),answers=review,seconds_used=int(p.get('seconds_used',0))))
    mem=db.query(StudyMemory).filter_by(user_id=user_id).first() or StudyMemory(user_id=user_id); mem.weak_topics=list(dict.fromkeys(list(mem.weak_topics or [])+weak))[:10]; mem.burnout_risk=min(1.0,(mem.burnout_risk or 0)+(.08 if score/total<.5 else -0.03)); db.add(mem)
    u=db.query(User).filter_by(id=user_id).first()
    if u: u.xp+=score*10; u.level=max(1,u.xp//200+1); db.add(u)
    if score==total: db.add(Achievement(user_id=user_id,key='perfect_quiz',title='Perfect Quiz',unlocked=True))
    db.commit(); return {'score':score,'total':total,'percent':round(score/total*100),'weak_topics':list(set(weak)),'review':review,'coach_message':coach_message(list(set(weak)))}
