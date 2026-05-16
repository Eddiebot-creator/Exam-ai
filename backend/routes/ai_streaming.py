from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from database import get_db, Note, ChatMessage, StudyMemory
from services.ai_provider import generate_ai_answer, stream_ai_answer
from security_jwt import get_current_user_id

router = APIRouter(prefix="/ai", tags=["Streaming AI Tutor"])

def build_context(db: Session, user_id: int, note_id=None) -> str:
    note = (
        db.query(Note).filter_by(id=note_id, user_id=user_id).first()
        if note_id
        else db.query(Note).filter_by(user_id=user_id).order_by(Note.id.desc()).first()
    )
    mem = db.query(StudyMemory).filter_by(user_id=user_id).first()
    weak = mem.weak_topics if mem and mem.weak_topics else []
    note_context = note.extracted_text[:1800] if note else "No notes uploaded yet"
    return f"Weak topics: {', '.join(weak) if weak else 'None yet'}\nNote context: {note_context}"

@router.post("/chat-v2")
async def chat_v2(payload: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    message = payload.get("message", "")
    context = build_context(db, user_id, payload.get("note_id"))
    prompt = f"{context}\n\nStudent question: {message}"
    answer = await generate_ai_answer(prompt)

    db.add(ChatMessage(user_id=user_id, note_id=payload.get("note_id"), role="user", content=message))
    db.add(ChatMessage(user_id=user_id, note_id=payload.get("note_id"), role="assistant", content=answer))
    db.commit()

    return {"answer": answer}

@router.post("/stream")
async def chat_stream(payload: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    message = payload.get("message", "")
    context = build_context(db, user_id, payload.get("note_id"))
    prompt = f"{context}\n\nStudent question: {message}"

    async def event_generator():
        async for chunk in stream_ai_answer(prompt):
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
