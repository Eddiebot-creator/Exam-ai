from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Note, ChatMessage, StudyMemory

router = APIRouter(prefix="/tutor-v2", tags=["AI Tutor"])

@router.post("/chat")
def chat(payload: dict, db: Session = Depends(get_db)):
    user_id = int(payload.get("user_id", 1))
    message = payload.get("message", "")
    note_id = payload.get("note_id")
    note = db.query(Note).filter_by(id=note_id, user_id=user_id).first() if note_id else db.query(Note).filter_by(user_id=user_id).first()
    mem = db.query(StudyMemory).filter_by(user_id=user_id).first()
    context = note.extracted_text[:1200] if note else ""
    weak = (mem.weak_topics if mem else []) or ["your current topic"]
    answer = (
        f"Let’s handle this calmly. Based on your notes and weak-topic memory, you should connect this question to {weak[0]}.\n\n"
        f"Question: {message}\n\n"
        f"Step 1: Identify the main idea.\n"
        f"Step 2: Break it into smaller parts.\n"
        f"Step 3: Practice with one example.\n"
        f"Step 4: Try a short quiz to confirm understanding.\n\n"
        f"Note context used: {context[:250] if context else 'No uploaded note context yet.'}"
    )
    db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="user", content=message))
    db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="assistant", content=answer))
    db.commit()
    return {"answer": answer, "context_note_id": note.id if note else None, "suggestions": ["Explain like I am 12", "Generate 5 MCQs", "Summarize this topic"]}

@router.get("/{user_id}/history")
def history(user_id: int, db: Session = Depends(get_db)):
    items = db.query(ChatMessage).filter_by(user_id=user_id).order_by(ChatMessage.id.desc()).limit(50).all()
    return [{"role": x.role, "content": x.content, "created_at": x.created_at.isoformat()} for x in reversed(items)]
