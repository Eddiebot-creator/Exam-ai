from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Flashcard, Note
from services.ai_provider import generate_ai_answer
from security_jwt import get_current_user_id

router = APIRouter(prefix="/flashcards-ai", tags=["AI Flashcards + Spaced Repetition"])

@router.post("/generate/{note_id}")
async def generate(note_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    note = db.query(Note).filter_by(id=note_id, user_id=user_id).first()
    if not note:
        return {"error": "Note not found"}

    prompt = "Create 10 flashcards from this note. Format each as Q: question | A: answer.\n\n" + note.extracted_text[:3000]
    raw = await generate_ai_answer(prompt)
    created = []

    for line in raw.splitlines():
        if "Q:" in line and "A:" in line:
            q = line.split("Q:", 1)[1].split("| A:", 1)[0].strip()
            a = line.split("| A:", 1)[1].strip()
            card = Flashcard(user_id=user_id, note_id=note_id, topic=(note.topics or ["General"])[0], question=q, answer=a)
            db.add(card)
            created.append(card)

    db.commit()
    return {"created": len(created), "raw": raw if not created else None}

@router.get("/due")
def due_cards(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    cards = db.query(Flashcard).filter(Flashcard.user_id == user_id, Flashcard.due_at <= datetime.utcnow()).all()
    return [{"id": c.id, "topic": c.topic, "question": c.question, "answer": c.answer} for c in cards]

@router.post("/review/{card_id}")
def review(card_id: int, payload: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    card = db.query(Flashcard).filter_by(id=card_id, user_id=user_id).first()
    if not card:
        return {"error": "Card not found"}

    correct = bool(payload.get("correct", False))
    card.ease = max(1.3, card.ease + (0.15 if correct else -0.3))
    card.interval_days = max(1, round(card.interval_days * card.ease)) if correct else 1
    card.due_at = datetime.utcnow() + timedelta(days=card.interval_days)
    card.mastered = correct and card.interval_days >= 7
    db.commit()
    return {"ok": True, "next_due_at": card.due_at.isoformat(), "interval_days": card.interval_days}
