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

@router.post("/upload")
async def upload(
    user_id: int = Form(...),
    title: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    raw = await file.read()
    filename = file.filename or "uploaded_file"

    extracted_text = extract_text(filename, raw).replace("\x00", "").strip()
    topics = detect_topics(extracted_text)

    note = Note(
        user_id=user_id,
        title=title,
        file_name=filename,
        file_path="",
        extracted_text=extracted_text,
        topics=topics,
        summary=make_summary(extracted_text),
    )

    db.add(note)
    db.commit()
    db.refresh(note)
    generated = gen(db, user_id, note)

    data = payload(note)
    data.update({
        "message": "Note uploaded and study materials generated.",
        "generated": generated,
    })
    return data

@router.get('/{note_id}/materials')
def note_materials(note_id: int, user_id: int, db: Session = Depends(get_db)):
    note = db.query(Note).filter_by(id=note_id, user_id=user_id).first()
    if not note:
        raise HTTPException(404, 'Note not found.')
    cards = db.query(Flashcard).filter_by(user_id=user_id, note_id=note_id).all()
    questions = db.query(Mcq).filter_by(user_id=user_id, note_id=note_id).all()
    return {
        'note': payload(note),
        'flashcards': [
            {'id': x.id, 'topic': x.topic, 'question': x.question, 'answer': x.answer, 'mastered': x.mastered}
            for x in cards
        ],
        'mcqs': [
            {'id': x.id, 'topic': x.topic, 'question': x.question, 'options': x.options, 'answer_index': x.answer_index, 'explanation': x.explanation}
            for x in questions
        ],
    }

@router.post('/{note_id}/regenerate')
def regenerate(note_id: int, p: dict, db: Session = Depends(get_db)):
    user_id = int(p.get('user_id', 1))
    note = db.query(Note).filter_by(id=note_id, user_id=user_id).first()
    if not note:
        raise HTTPException(404, 'Note not found.')
    db.query(Flashcard).filter_by(user_id=user_id, note_id=note_id).delete()
    db.query(Mcq).filter_by(user_id=user_id, note_id=note_id).delete()
    db.commit()
    generated = gen(db, user_id, note)
    return {'ok': True, 'note': payload(note), 'generated': generated}
    
def gen(db, user_id, n):
    flashcard_count = 0
    mcq_count = 0
    try:
        for x in make_flashcards(user_id, n.id, n.extracted_text or '', n.topics or []):
            db.add(Flashcard(**x))
            flashcard_count += 1
        for x in make_mcqs(user_id, n.id, n.extracted_text or '', n.topics or []):
            db.add(Mcq(**x))
            mcq_count += 1
        db.commit()
        return {'flashcards': flashcard_count, 'mcqs': mcq_count}
    except Exception as exc:
        # Do not fail note saving if generated learning materials fail.
        db.rollback()
        return {'flashcards': 0, 'mcqs': 0, 'error': str(exc)}

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
