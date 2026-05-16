from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from database import get_db, Note, Flashcard, Mcq
from services.ocr_service import extract_text_from_upload
from services.learning_tools import topics_from_text, summary_from_text, flashcards_from_text, mcqs_from_text

router = APIRouter(prefix="/notes-v2", tags=["Smart Note Engine"])

@router.post("/text")
def create_text_note(user_id: int, title: str, text: str, db: Session = Depends(get_db)):
    topics = topics_from_text(text)
    note = Note(user_id=user_id, title=title, extracted_text=text, topics=topics, summary=summary_from_text(text))
    db.add(note); db.commit(); db.refresh(note)
    _generate_materials(db, user_id, note)
    return _note_payload(note)

@router.post("/upload")
async def upload_note(user_id: int = Form(...), title: str = Form("Uploaded note"), file: UploadFile = File(...), db: Session = Depends(get_db)):
    raw = await file.read()
    text = extract_text_from_upload(file.filename, raw)
    topics = topics_from_text(text)
    note = Note(user_id=user_id, title=title, file_name=file.filename, extracted_text=text, topics=topics, summary=summary_from_text(text))
    db.add(note); db.commit(); db.refresh(note)
    _generate_materials(db, user_id, note)
    return _note_payload(note)

@router.get("/{user_id}")
def list_notes(user_id: int, db: Session = Depends(get_db)):
    return [_note_payload(n) for n in db.query(Note).filter_by(user_id=user_id).order_by(Note.id.desc()).all()]

def _generate_materials(db: Session, user_id: int, note: Note):
    for item in flashcards_from_text(user_id, note.id, note.extracted_text, note.topics or []):
        db.add(Flashcard(**item))
    for item in mcqs_from_text(user_id, note.id, note.extracted_text, note.topics or []):
        db.add(Mcq(**item))
    db.commit()

def _note_payload(note: Note):
    return {"id": note.id, "user_id": note.user_id, "title": note.title, "file_name": note.file_name, "topics": note.topics or [], "summary": note.summary}
