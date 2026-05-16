
from fastapi import APIRouter,Depends,UploadFile,File,Form
from sqlalchemy.orm import Session
from database import get_db,Note,Flashcard,Mcq
from services.learning_engine import extract_text,detect_topics,make_summary,make_flashcards,make_mcqs
import os
router=APIRouter(prefix='/notes',tags=['Notes / Smart Note Engine'])
@router.get('')
def list_notes(user_id:int,db:Session=Depends(get_db)): return [payload(n) for n in db.query(Note).filter_by(user_id=user_id).order_by(Note.id.desc()).all()]
@router.post('/text')
def text_note(p:dict,db:Session=Depends(get_db)):
    user_id=int(p.get('user_id',1)); text=p.get('text',''); topics=detect_topics(text); n=Note(user_id=user_id,title=p.get('title','Text note'),extracted_text=text,topics=topics,summary=make_summary(text)); db.add(n); db.commit(); db.refresh(n); gen(db,user_id,n); return payload(n)
@router.post('/upload')
async def upload(user_id:int=Form(...),title:str=Form('Uploaded note'),file:UploadFile=File(...),db:Session=Depends(get_db)):
    os.makedirs('uploads/notes',exist_ok=True); raw=await file.read(); path=f'uploads/notes/{user_id}_{file.filename}'; open(path,'wb').write(raw); text=extract_text(file.filename,raw); topics=detect_topics(text); n=Note(user_id=user_id,title=title,file_name=file.filename,file_path=path,extracted_text=text,topics=topics,summary=make_summary(text)); db.add(n); db.commit(); db.refresh(n); gen(db,user_id,n); return payload(n)
def gen(db,user_id,n):
    for x in make_flashcards(user_id,n.id,n.extracted_text,n.topics or []): db.add(Flashcard(**x))
    for x in make_mcqs(user_id,n.id,n.extracted_text,n.topics or []): db.add(Mcq(**x))
    db.commit()
def payload(n): return {'id':n.id,'user_id':n.user_id,'title':n.title,'file_name':n.file_name,'topics':n.topics or [],'summary':n.summary,'created_at':n.created_at.isoformat()}
