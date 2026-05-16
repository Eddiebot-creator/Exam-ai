from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Mcq, StudyMemory
from security_jwt import get_current_user_id

router = APIRouter(prefix="/adaptive-quiz", tags=["Adaptive Quiz"])

@router.get("/next")
def next_quiz(limit: int = 10, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    weak_topics = memory.weak_topics if memory and memory.weak_topics else []
    query = db.query(Mcq).filter_by(user_id=user_id)

    if weak_topics:
        questions = query.filter(Mcq.topic.in_(weak_topics)).limit(limit).all()
        if len(questions) < limit:
            questions += query.limit(limit - len(questions)).all()
    else:
        questions = query.limit(limit).all()

    return {
        "focus_topics": weak_topics,
        "questions": [{"id": q.id, "topic": q.topic, "question": q.question, "options": q.options} for q in questions],
    }
