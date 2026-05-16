from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, User, QuizAttempt, ProgressEvent, StudyMemory, Note, Flashcard, Mcq
from security_jwt import get_current_user_id

router = APIRouter(prefix="/analytics", tags=["Analytics Dashboard"])

@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    user = db.query(User).filter_by(id=user_id).first()
    attempts = db.query(QuizAttempt).filter_by(user_id=user_id).all()
    events = db.query(ProgressEvent).filter_by(user_id=user_id).all()
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()

    total_score = sum(a.score for a in attempts)
    total_questions = sum(a.total for a in attempts) or 1

    return {
        "xp": user.xp if user else 0,
        "level": user.level if user else 1,
        "streak_days": user.streak_days if user else 0,
        "average_score": round((total_score / total_questions) * 100),
        "study_minutes": round(sum(e.seconds for e in events) / 60),
        "weak_topics": memory.weak_topics if memory else [],
        "notes_count": db.query(Note).filter_by(user_id=user_id).count(),
        "flashcards_count": db.query(Flashcard).filter_by(user_id=user_id).count(),
        "mcqs_count": db.query(Mcq).filter_by(user_id=user_id).count(),
        "recommendation": "Focus on your weakest topic for 25 minutes, then take a 10-question quiz.",
    }
