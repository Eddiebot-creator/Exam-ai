
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, Note, ChatMessage
from services.learning_engine import coach_message
from services.autonomous_orchestrator import tutor_context, process_learning_event

router = APIRouter(prefix="/ai", tags=["AI Tutor"])


@router.post("/chat")
def chat(p: dict, db: Session = Depends(get_db)):
    user_id = int(p.get("user_id", 1))
    note_id = p.get("note_id")
    msg = p.get("message", "")
    topic = p.get("topic") or "General"

    note = (
        db.query(Note).filter_by(id=note_id, user_id=user_id).first()
        if note_id
        else db.query(Note).filter_by(user_id=user_id).first()
    )

    ctx = tutor_context(db, user_id, msg)
    focus_topic = ctx["context"].get("focus_topic", topic)
    tone = ctx["context"].get("emotional_tone", "encouraging")
    tutor_style = ctx["context"].get("tutor_style", "simple")
    next_action = ctx["context"].get("next_best_action", "Continue studying")
    readiness = ctx["context"].get("readiness", 50)
    exam_risk = ctx["context"].get("exam_risk", "normal")
    note_context = note.extracted_text[:500] if note else "No uploaded note context yet."

    weak = ctx["context"].get("weak_topics") or [focus_topic]

    answer = (
        f"{coach_message(weak)}\n\n"
        f"Adaptive mode: {tone}\n"
        f"Explanation style: {tutor_style}\n"
        f"Focus topic: {focus_topic}\n"
        f"Exam readiness: {readiness}% ({exam_risk} risk)\n\n"
        f"Your question: {msg}\n\n"
        f"Answer:\n"
        f"1. Main idea: let us focus on {focus_topic} first.\n"
        f"2. Simple explanation: I will keep this {tutor_style.replace('_', ' ')} because that fits your recent learning pattern.\n"
        f"3. Example: connect this idea directly to your uploaded note or current weak topic.\n"
        f"4. Practice: answer one easier question first, then move to adaptive difficulty.\n\n"
        f"Next best action: {next_action}\n\n"
        f"Note context: {note_context}"
    )

    db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="user", content=msg))
    db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="assistant", content=answer))

    process_learning_event(db, {
        "user_id": user_id,
        "event_type": "tutor_chat",
        "topic": focus_topic,
        "correct": True,
        "confidence": 0.55,
        "difficulty": "medium",
        "seconds": 60,
        "payload": {"message": msg, "source": "ai_chat"}
    })

    return {
        "answer": answer,
        "context_note_id": note.id if note else None,
        "adaptive_context": ctx["context"],
    }


@router.get("/history/{user_id}")
def history(user_id: int, db: Session = Depends(get_db)):
    messages = (
        db.query(ChatMessage)
        .filter_by(user_id=user_id)
        .order_by(ChatMessage.id.desc())
        .limit(50)
        .all()
    )

    return [
        {
            "role": x.role,
            "content": x.content,
            "created_at": x.created_at.isoformat(),
        }
        for x in reversed(messages)
    ]
