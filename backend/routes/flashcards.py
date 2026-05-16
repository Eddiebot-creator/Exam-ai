
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,Flashcard
from datetime import datetime,timedelta
router=APIRouter(prefix='/flashcards',tags=['Flashcards'])
@router.get('/{user_id}')
def cards(user_id:int,db:Session=Depends(get_db)): return [{'id':c.id,'topic':c.topic,'question':c.question,'answer':c.answer,'mastered':c.mastered,'due_at':c.due_at.isoformat()} for c in db.query(Flashcard).filter_by(user_id=user_id).all()]
@router.post('/{card_id}/review')
def review(card_id:int,p:dict,db:Session=Depends(get_db)):
    c=db.query(Flashcard).filter_by(id=card_id).first();
    if not c: return {'ok':False}
    correct=bool(p.get('correct',False)); c.mastered=correct; c.interval_days=c.interval_days+2 if correct else 1; c.due_at=datetime.utcnow()+timedelta(days=c.interval_days); db.commit(); return {'ok':True,'interval_days':c.interval_days}
