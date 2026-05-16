
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from services.autonomous_orchestrator import process_learning_event, adaptive_home, tutor_context

router = APIRouter(prefix="/autonomous", tags=["Autonomous Intelligence"])

@router.post("/learning-event")
def learning_event(payload: dict, db: Session = Depends(get_db)):
    return process_learning_event(db, payload)

@router.get("/adaptive-home/{user_id}")
def get_adaptive_home(user_id: int, db: Session = Depends(get_db)):
    return adaptive_home(db, user_id)

@router.post("/tutor-context")
def get_tutor_context(payload: dict, db: Session = Depends(get_db)):
    return tutor_context(db, int(payload.get("user_id", 1)), payload.get("message", ""))

@router.get("/next-best-action/{user_id}")
def next_best_action(user_id: int, db: Session = Depends(get_db)):
    home = adaptive_home(db, user_id)
    return {
        "next_best_action": home["next_best_action"],
        "daily_mission": home["daily_mission"],
        "emotional_tone": home["emotional_tone"],
        "recommended_room": home["recommended_room"],
        "exam_risk": home["exam_risk"],
    }
