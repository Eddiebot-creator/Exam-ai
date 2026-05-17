
from fastapi import APIRouter,Depends,HTTPException,UploadFile,File
from sqlalchemy.orm import Session
from database import get_db,User,Note,QuizAttempt,ProgressEvent,StudyMemory,LearningEvent,ConceptMastery,AdaptiveState,Flashcard,Mcq,ChatMessage,Achievement,WellnessCheck,StudyRoom
from security import verify_password,hash_password
from routes.auth import user_payload
import os
router=APIRouter(prefix='/profile',tags=['Profile'])
@router.put('/{user_id}')
def update_profile(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    for k in ['full_name','email','avatar_character','bio','preferred_style']:
        if k in p: setattr(u,k,p[k])
    db.commit(); db.refresh(u); return user_payload(u)
@router.put('/{user_id}/password')
def change_password(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    if not verify_password(p.get('current_password',''),u.password_hash): raise HTTPException(400,'Current password is wrong.')
    u.password_hash=hash_password(p.get('new_password','')); db.commit(); return {'ok':True}
@router.post('/{user_id}/picture')
async def picture(user_id:int,file:UploadFile=File(...),db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    os.makedirs('uploads/profile',exist_ok=True); path=f'uploads/profile/{user_id}_{file.filename}'; open(path,'wb').write(await file.read()); u.profile_image_url='/'+path.replace('\\', '/'); db.commit(); db.refresh(u); return user_payload(u)

@router.get('/{user_id}/export')
def export_data(user_id:int,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first()
    if not u: raise HTTPException(404,'User not found.')
    memory=db.query(StudyMemory).filter_by(user_id=user_id).first()
    state=db.query(AdaptiveState).filter_by(user_id=user_id).first()
    return {
        'user': user_payload(u),
        'notes': [{'id':n.id,'title':n.title,'topics':n.topics,'created_at':n.created_at.isoformat()} for n in db.query(Note).filter_by(user_id=user_id).all()],
        'quiz_attempts': [{'id':q.id,'score':q.score,'total':q.total,'weak_topics':q.weak_topics,'created_at':q.created_at.isoformat()} for q in db.query(QuizAttempt).filter_by(user_id=user_id).all()],
        'progress_events': [{'id':e.id,'activity':e.activity,'seconds':e.seconds,'xp':e.xp,'created_at':e.created_at.isoformat()} for e in db.query(ProgressEvent).filter_by(user_id=user_id).all()],
        'learning_events': [{'id':e.id,'event_type':e.event_type,'topic':e.topic,'correct':e.correct,'created_at':e.created_at.isoformat()} for e in db.query(LearningEvent).filter_by(user_id=user_id).all()],
        'mastery': [{'topic':m.topic,'mastery':m.mastery,'confidence':m.confidence,'next_review_at':m.next_review_at.isoformat() if m.next_review_at else None} for m in db.query(ConceptMastery).filter_by(user_id=user_id).all()],
        'memory': {'weak_topics': memory.weak_topics, 'strong_topics': memory.strong_topics, 'burnout_risk': memory.burnout_risk} if memory else {},
        'adaptive_state': {'readiness': state.readiness, 'tone': state.emotional_tone, 'next_best_action': state.next_best_action, 'exam_risk': state.exam_risk} if state else {},
        'privacy': 'Student-controlled export. Parent and lecturer sharing should require explicit consent.',
    }

@router.delete('/{user_id}/data')
def delete_student_data(user_id:int,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first()
    if not u: raise HTTPException(404,'User not found.')
    for model in [Note,Flashcard,Mcq,QuizAttempt,ProgressEvent,ChatMessage,StudyMemory,Achievement,StudyRoom,WellnessCheck,LearningEvent,ConceptMastery,AdaptiveState]:
        db.query(model).filter_by(user_id=user_id).delete(synchronize_session=False) if hasattr(model,'user_id') else None
    db.query(StudyRoom).filter_by(owner_id=user_id).delete(synchronize_session=False)
    u.xp=0; u.level=1; u.streak_days=0
    db.commit()
    return {'ok': True, 'message': 'Student learning data deleted. Account login remains active.'}
