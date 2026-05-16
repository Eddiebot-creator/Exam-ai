from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Note, QuizAttempt, StudyMemory, User
from services.ai_provider import generate_ai_answer
from security_jwt import get_current_user_id

router = APIRouter(prefix="/exam-ai", tags=["Exam Prediction AI"])

@router.get("/prediction")
async def prediction(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    user = db.query(User).filter_by(id=user_id).first()
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    attempts = db.query(QuizAttempt).filter_by(user_id=user_id).all()
    notes = db.query(Note).filter_by(user_id=user_id).all()

    avg = round(sum(a.score for a in attempts) / max(1, sum(a.total for a in attempts)) * 100) if attempts else 74
    weak = memory.weak_topics if memory and memory.weak_topics else []
    topics = []
    for n in notes:
        topics += (n.topics or [])

    prompt = f"""
Course: {user.exam_course if user else "Unknown"}
Target score: {user.target_score if user else 80}
Average quiz score: {avg}
Weak topics: {weak}
Uploaded note topics: {topics[:20]}

Predict likely exam topics, readiness, and a 7-day revision plan.
"""
    ai = await generate_ai_answer(prompt)
    return {"average_score": avg, "weak_topics": weak, "ai_prediction": ai}
