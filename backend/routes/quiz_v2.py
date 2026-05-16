from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, Mcq, QuizAttempt, StudyMemory, Achievement
from services.ai_memory import update_memory_from_quiz

router = APIRouter(prefix="/quiz-v2", tags=["Complete Quiz Engine"])

@router.get("/{user_id}/start")
def start_quiz(user_id: int, mode: str = "practice", limit: int = 10, db: Session = Depends(get_db)):
    qs = db.query(Mcq).filter_by(user_id=user_id).limit(limit).all()
    return {
        "mode": mode,
        "timer_seconds": 900 if mode in ["mock", "exam"] else 0,
        "questions": [
            {"id": q.id, "topic": q.topic, "question": q.question, "options": q.options, "explanation": q.explanation}
            for q in qs
        ],
    }

@router.post("/{user_id}/submit")
def submit_quiz(user_id: int, payload: dict, db: Session = Depends(get_db)):
    answers = payload.get("answers", [])
    score = 0
    weak = []
    review = []
    for ans in answers:
        q = db.query(Mcq).filter_by(id=ans.get("question_id"), user_id=user_id).first()
        if not q:
            continue
        correct = int(ans.get("selected_index", -1)) == q.answer_index
        if correct:
            score += 1
        else:
            weak.append(q.topic)
        review.append({"question_id": q.id, "correct": correct, "answer_index": q.answer_index, "explanation": q.explanation, "topic": q.topic})
    total = max(1, len(review))
    attempt = QuizAttempt(user_id=user_id, mode=payload.get("mode", "practice"), score=score, total=total, weak_topics=list(set(weak)), answers=review, seconds_used=int(payload.get("seconds_used", 0)))
    db.add(attempt)

    mem = db.query(StudyMemory).filter_by(user_id=user_id).first() or StudyMemory(user_id=user_id)
    updated = update_memory_from_quiz({"weak_topics": mem.weak_topics or [], "burnout_risk": mem.burnout_risk, "preferred_style": mem.preferred_style}, list(set(weak)), (score / total) * 100)
    mem.weak_topics = updated["weak_topics"]
    mem.burnout_risk = updated["burnout_risk"]
    db.add(mem)

    if score == total:
        db.add(Achievement(user_id=user_id, key="perfect_quiz", title="Perfect Quiz", unlocked=True))
    db.commit()
    return {"score": score, "total": total, "percent": round(score / total * 100), "weak_topics": list(set(weak)), "review": review, "coach_message": updated["coach_message"]}
