import os
from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.orm import Session
from database import get_db, Note
from services.ocr_engine import extract_text_from_file
from services.learning_engine import detect_topics, make_summary
from security_jwt import get_current_user_id

router = APIRouter(prefix="/ocr", tags=["OCR Note Scanning"])

@router.post("/scan-note")
async def scan_note(file: UploadFile = File(...), db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    os.makedirs("uploads/ocr", exist_ok=True)
    path = f"uploads/ocr/{user_id}_{file.filename}"
    with open(path, "wb") as f:
        f.write(await file.read())

    text = extract_text_from_file(path)
    topics = detect_topics(text)
    note = Note(
        user_id=user_id,
        title=f"OCR: {file.filename}",
        file_name=file.filename,
        file_path=path,
        extracted_text=text,
        topics=topics,
        summary=make_summary(text),
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return {"note_id": note.id, "text": text, "topics": topics, "summary": note.summary}
