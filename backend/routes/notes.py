from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database import get_db, Note, Flashcard, Mcq
from services.learning_engine import extract_text, detect_topics, make_summary, make_flashcards, make_mcqs
import os

router = APIRouter(prefix='/notes', tags=['Notes / Smart Note Engine'])

@router.get('')
def list_notes(user_id: int, db: Session = Depends(get_db)):
    return [payload(n) for n in db.query(Note).filter_by(user_id=user_id).order_by(Note.id.desc()).all()]

@router.post('/text')
def text_note(p: dict, db: Session = Depends(get_db)):
    return _create_text_note(p, db)

@router.post('/create')
def create_note(p: dict, db: Session = Depends(get_db)):
    # Alias for mobile/frontend tools that call /notes/create.
    if 'content' in p and 'text' not in p:
        p['text'] = p.get('content')
    return _create_text_note(p, db)

def _create_text_note(p: dict, db: Session):
    user_id = int(p.get('user_id', 1))
    text = (p.get('text') or p.get('content') or '').strip()
    title = (p.get('title') or 'Text note').strip() or 'Text note'
    if not text:
        raise HTTPException(400, 'Paste a note before saving.')
    try:
        topics = detect_topics(text)
        n = Note(user_id=user_id, title=title, extracted_text=text, topics=topics, summary=make_summary(text))
        db.add(n)
        db.commit()
        db.refresh(n)
        gen(db, user_id, n)
        return payload(n)
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(500, f'Note database error: {str(exc)}')

@router.post('/upload')
async def upload(user_id: int = Form(...), title: str = Form('Uploaded note'), file: UploadFile = File(...), db: Session = Depends(get_db)):
    try:
        os.makedirs('uploads/notes', exist_ok=True)
        raw = await file.read()
        safe_name = file.filename.replace('/', '_').replace('\\', '_')
        path = f'uploads/notes/{user_id}_{safe_name}'
        with open(path, 'wb') as f:
            f.write(raw)
        text = extract_text(file.filename, raw)
        topics = detect_topics(text)
        n = Note(user_id=user_id, title=title or safe_name, file_name=file.filename, file_path=path, extracted_text=text, topics=topics, summary=make_summary(text))
        db.add(n)
        db.commit()
        db.refresh(n)
        gen(db, user_id, n)
        return payload(n)
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(500, f'Upload database error: {str(exc)}')

def gen(db, user_id, n):
    try:
        for x in make_flashcards(user_id, n.id, n.extracted_text or '', n.topics or []):
            db.add(Flashcard(**x))
        for x in make_mcqs(user_id, n.id, n.extracted_text or '', n.topics or []):
            db.add(Mcq(**x))
        db.commit()
    except Exception:
        # Do not fail note saving if generated learning materials fail.
        db.rollback()

def payload(n):
    return {
        'id': n.id,
        'user_id': n.user_id,
        'title': n.title,
        'file_name': getattr(n, 'file_name', '') or '',
        'topics': n.topics or [],
        'summary': n.summary or '',
        'extracted_text': (getattr(n, 'extracted_text', '') or '')[:500],
        'created_at': n.created_at.isoformat(),
    }
