from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database import get_db, Note, Flashcard, Mcq
from services.learning_engine import clean_text, extract_text, detect_topics, make_summary, make_flashcards, make_mcqs
from services.ai_service import generate_flashcards as ai_flashcards, generate_mcqs as ai_mcqs, summarize_text
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
        n = Note(user_id=user_id, title=title, extracted_text=text, topics=topics, summary=summarize_text(text, "short"))
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

    extracted_text = clean_text(extract_text(filename, raw))
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

    try:
        db.add(note)
        db.commit()
        db.refresh(note)
        generated = gen(db, user_id, note)
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(500, "Upload failed because the database schema is still updating. Redeploy once, then try again.") from exc

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
        text = n.extracted_text or ''
        topics = n.topics or []
        topic = topics[0] if topics else 'General'
        cards = []
        try:
            cards = [
                {
                    'user_id': user_id,
                    'note_id': n.id,
                    'topic': topic,
                    'question': item.get('front_text') or item.get('question') or 'Review this concept',
                    'answer': item.get('back_text') or item.get('answer') or 'Review your note for this answer.',
                }
                for item in ai_flashcards(text, count=10)
            ]
        except Exception as exc:
            print("AI flashcards failed:", exc)
        if not cards:
            cards = make_flashcards(user_id, n.id, text, topics)

        questions = []
        try:
            letters = {'A': 0, 'B': 1, 'C': 2, 'D': 3}
            for item in ai_mcqs(text, count=8, difficulty='medium'):
                questions.append({
                    'user_id': user_id,
                    'note_id': n.id,
                    'topic': topic,
                    'question': item.get('question') or 'What is the best answer?',
                    'options': item.get('options') or [],
                    'answer_index': letters.get(str(item.get('correct_answer', 'A')).upper()[:1], 0),
                    'explanation': item.get('explanation') or 'Review this concept in your note.',
                })
        except Exception as exc:
            print("AI MCQs failed:", exc)
        if not questions:
            questions = make_mcqs(user_id, n.id, text, topics)

        for x in cards:
            db.add(Flashcard(**x))
            flashcard_count += 1
        for x in questions:
            db.add(Mcq(**x))
            mcq_count += 1
        db.commit()
        return {'flashcards': flashcard_count, 'mcqs': mcq_count}
    except Exception as exc:
        # Do not fail note saving if generated learning materials fail.
        db.rollback()
        print("Material generation failed:", exc)
        return {'flashcards': 0, 'mcqs': 0, 'error': 'Study material generation is warming up. Try regenerate in a moment.'}

def payload(n):
    return {
        'id': n.id,
        'user_id': n.user_id,
        'title': clean_text(n.title),
        'file_name': getattr(n, 'file_name', '') or '',
        'topics': n.topics or [],
        'summary': clean_text(n.summary or ''),
        'extracted_text': clean_text(getattr(n, 'extracted_text', '') or '')[:500],
        'created_at': n.created_at.isoformat(),
    }
