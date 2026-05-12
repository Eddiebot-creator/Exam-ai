from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from database import get_connection
from schemas import TextNoteRequest
from services.file_text import extract_upload_text

router = APIRouter(prefix="/notes", tags=["notes"])

FREE_UPLOAD_LIMIT = 3


def _assert_can_upload(user_id: int) -> None:
    with get_connection() as db:
        user = db.execute(
            "SELECT subscription_status, uploads_used FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user["subscription_status"] != "premium" and user["uploads_used"] >= FREE_UPLOAD_LIMIT:
        raise HTTPException(
            status_code=402,
            detail="Free plan limit reached. Upgrade to premium for unlimited uploads.",
        )


@router.post("/text")
def create_text_note(payload: TextNoteRequest):
    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Note text is required")
    _assert_can_upload(payload.user_id)
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO notes (user_id, title, extracted_text) VALUES (?, ?, ?)",
            (payload.user_id, payload.title.strip(), text),
        )
        db.execute("UPDATE users SET uploads_used = uploads_used + 1 WHERE id = ?", (payload.user_id,))
        note_id = cursor.lastrowid
    return {"id": note_id, "title": payload.title, "extracted_text": text}


@router.post("/upload")
async def upload_note(user_id: int = Form(...), title: str = Form(...), file: UploadFile = File(...)):
    _assert_can_upload(user_id)
    text = await extract_upload_text(file)
    if not text:
        raise HTTPException(status_code=400, detail="Could not extract readable text from this file")
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO notes (user_id, title, file_name, extracted_text) VALUES (?, ?, ?, ?)",
            (user_id, title.strip(), file.filename, text),
        )
        db.execute("UPDATE users SET uploads_used = uploads_used + 1 WHERE id = ?", (user_id,))
        note_id = cursor.lastrowid
    return {"id": note_id, "title": title, "file_name": file.filename, "extracted_text": text[:2000]}


@router.get("")
def list_notes(user_id: int = 1):
    with get_connection() as db:
        rows = db.execute(
            "SELECT id, title, file_name, created_at FROM notes WHERE user_id = ? ORDER BY id DESC",
            (user_id,),
        ).fetchall()
    return [dict(row) for row in rows]


@router.get("/{note_id}")
def get_note(note_id: int):
    with get_connection() as db:
        note = db.execute("SELECT * FROM notes WHERE id = ?", (note_id,)).fetchone()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return dict(note)
