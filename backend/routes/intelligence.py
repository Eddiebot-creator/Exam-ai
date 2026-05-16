
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, User, StudyMemory, QuizAttempt, ProgressEvent, Note
from services.intelligence_engine import (
    adaptive_difficulty, build_daily_mission, calculate_gpa,
    curriculum_recommendation, generate_timetable, next_review_date, readiness_score,
)

router = APIRouter(prefix="/intelligence", tags=["Core Intelligence Layer"])

@router.get("/daily-mission/{user_id}")
def daily_mission(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(id=user_id).first()
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    attempts = db.query(QuizAttempt).filter_by(user_id=user_id).all()
    events = db.query(ProgressEvent).filter_by(user_id=user_id).all()
    avg = round(sum(a.score for a in attempts) / max(1, sum(a.total for a in attempts)) * 100) if attempts else 76
    weak = memory.weak_topics if memory and memory.weak_topics else ["Recursion"]

    days_left = 23
    if user and user.exam_date:
        try:
            days_left = max(0, (datetime.fromisoformat(user.exam_date).date() - datetime.utcnow().date()).days)
        except Exception:
            days_left = 23

    readiness = readiness_score(avg, len(weak), len(events), days_left)
    return build_daily_mission(user.exam_course if user else "CSC301", weak, days_left, readiness)

@router.get("/adaptive-quiz-plan/{user_id}")
def adaptive_quiz_plan(user_id: int, db: Session = Depends(get_db)):
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    attempts = db.query(QuizAttempt).filter_by(user_id=user_id).order_by(QuizAttempt.id.desc()).limit(5).all()
    scores = [round(a.score / max(1, a.total) * 100) for a in attempts]
    weak = memory.weak_topics if memory and memory.weak_topics else ["Recursion"]
    return adaptive_difficulty(scores or [76], weak, memory.burnout_risk if memory else 0)

@router.post("/spaced-review")
def spaced_review(payload: dict):
    return next_review_date(bool(payload.get("correct", False)), float(payload.get("confidence", 0.5)), float(payload.get("ease", 2.5)))

@router.post("/timetable")
def timetable(payload: dict, db: Session = Depends(get_db)):
    user_id = int(payload.get("user_id", 1))
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    weak = memory.weak_topics if memory and memory.weak_topics else []
    return {"plan": generate_timetable(payload.get("courses", []), weak, int(payload.get("days", 7)))}

@router.post("/gpa")
def gpa(payload: dict):
    return calculate_gpa(payload.get("courses", []))

@router.post("/curriculum")
def curriculum(payload: dict):
    return curriculum_recommendation(payload.get("school", ""), payload.get("course", ""), payload.get("weak_topics", []))

@router.get("/exam-countdown/{user_id}")
def exam_countdown(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(id=user_id).first()
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    notes = db.query(Note).filter_by(user_id=user_id).all()
    weak = memory.weak_topics if memory and memory.weak_topics else ["Recursion"]
    topics = []
    for note in notes:
        topics.extend(note.topics or [])

    days_left = 23
    if user and user.exam_date:
        try:
            days_left = max(0, (datetime.fromisoformat(user.exam_date).date() - datetime.utcnow().date()).days)
        except Exception:
            pass

    return {
        "course": user.exam_course if user else "CSC301",
        "days_left": days_left,
        "weak_topics": weak,
        "covered_topics": list(dict.fromkeys(topics))[:20],
        "message": f"{user.exam_course if user else 'Your exam'} is in {days_left} days. Focus on {weak[0]} today.",
    }
