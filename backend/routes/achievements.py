from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Achievement

router = APIRouter(prefix="/achievements", tags=["Achievement Economy"])

@router.get("/{user_id}")
def list_achievements(user_id: int, db: Session = Depends(get_db)):
    items = db.query(Achievement).filter_by(user_id=user_id).all()
    defaults = [
        {"key": "first_note", "title": "First Note", "unlocked": False},
        {"key": "seven_day_streak", "title": "7-Day Streak", "unlocked": False},
        {"key": "perfect_quiz", "title": "Perfect Quiz", "unlocked": False},
        {"key": "focus_hero", "title": "Focus Hero", "unlocked": False},
    ]
    existing = {a.key: {"key": a.key, "title": a.title, "unlocked": a.unlocked} for a in items}
    return [existing.get(d["key"], d) for d in defaults]

@router.post("/{user_id}/unlock")
def unlock(user_id: int, payload: dict, db: Session = Depends(get_db)):
    item = Achievement(user_id=user_id, key=payload.get("key", "custom"), title=payload.get("title", "Achievement"), unlocked=True)
    db.add(item); db.commit()
    return {"ok": True, "achievement": item.title}
