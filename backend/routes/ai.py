
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,Note,ChatMessage,StudyMemory
from services.learning_engine import coach_message
router=APIRouter(prefix='/ai',tags=['AI Tutor'])
@router.post('/chat')
def chat(p:dict,db:Session=Depends(get_db)):
    user_id=int(p.get('user_id',1)); note_id=p.get('note_id'); msg=p.get('message',''); note=db.query(Note).filter_by(id=note_id,user_id=user_id).first() if note_id else db.query(Note).filter_by(user_id=user_id).first(); mem=db.query(StudyMemory).filter_by(user_id=user_id).first(); weak=mem.weak_topics if mem and mem.weak_topics else ['your current topic']; context=note.extracted_text[:350] if note else 'No uploaded note context yet.'; answer=f"{coach_message(weak)}

Your question: {msg}

Step-by-step answer:
1. Identify the key idea.
2. Connect it to your notes.
3. Work through one example.
4. Test yourself with a short quiz.

Note context: {context}"; db.add(ChatMessage(user_id=user_id,note_id=note.id if note else None,role='user',content=msg)); db.add(ChatMessage(user_id=user_id,note_id=note.id if note else None,role='assistant',content=answer)); db.commit(); return {'answer':answer,'context_note_id':note.id if note else None}
@router.get('/history/{user_id}')
def history(user_id:int,db:Session=Depends(get_db)): return [{'role':x.role,'content':x.content,'created_at':x.created_at.isoformat()} for x in reversed(db.query(ChatMessage).filter_by(user_id=user_id).order_by(ChatMessage.id.desc()).limit(50).all())]
