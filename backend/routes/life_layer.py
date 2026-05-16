
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, User, StudyMemory, QuizAttempt, ProgressEvent
from services.psychology_engine import emotional_response, belief_score
from services.diagnostic_engine import diagnose_weak_area
from services.language_engine import language_prompt

router = APIRouter(prefix="/life-layer", tags=["Life Changing Product Layer"])

@router.post("/onboarding")
def onboarding(payload: dict, db: Session = Depends(get_db)):
    user_id = int(payload.get("user_id", 1))
    user = db.query(User).filter_by(id=user_id).first()

    if user:
        user.exam_course = payload.get("course", user.exam_course)
        user.exam_date = payload.get("exam_date", user.exam_date)
        user.target_score = int(payload.get("target_score", user.target_score or 80))
        db.commit()

    struggle = payload.get("biggest_struggle", "staying consistent")
    return {
        "message": "Your dashboard is now personalized.",
        "course": payload.get("course"),
        "exam_date": payload.get("exam_date"),
        "biggest_struggle": struggle,
        "first_mission": f"Start with one calm 20-minute session focused on {struggle}.",
    }

@router.get("/emotional-state/{user_id}")
def emotional_state(user_id: int, wrong_streak: int = 0, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(id=user_id).first()
    attempts = db.query(QuizAttempt).filter_by(user_id=user_id).all()
    events = db.query(ProgressEvent).filter_by(user_id=user_id).all()
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()

    avg = round(sum(a.score for a in attempts) / max(1, sum(a.total for a in attempts)) * 100) if attempts else 70
    belief = belief_score(
        streak_days=user.streak_days if user else 0,
        average_score=avg,
        completed_missions=len(events),
        burnout_risk=memory.burnout_risk if memory else 0,
    )
    response = emotional_response("normal", wrong_streak, datetime.utcnow().hour)
    return {"belief": belief, "coach_response": response}

@router.post("/diagnose")
def diagnose(payload: dict):
    return diagnose_weak_area(payload.get("topic", "General"), payload.get("answers", []))

@router.post("/local-language")
def local_language(payload: dict):
    return {
        "language": payload.get("language", "english"),
        "prompt": language_prompt(payload.get("language", "english"), payload.get("message", "")),
    }
