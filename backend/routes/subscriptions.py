from fastapi import APIRouter, HTTPException

from database import get_connection
from schemas import SubscriptionUpdateRequest

router = APIRouter(prefix="/subscription", tags=["subscription"])


@router.get("/status/{user_id}")
def status(user_id: int):
    with get_connection() as db:
        user = db.execute(
            "SELECT id, subscription_status, uploads_used FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    plan = user["subscription_status"]
    return {
        "user_id": user["id"],
        "plan": plan,
        "uploads_used": user["uploads_used"],
        "upload_limit": None if plan == "premium" else 3,
        "features": _features(plan),
    }


@router.post("/status/{user_id}")
def update_status(user_id: int, payload: SubscriptionUpdateRequest):
    if payload.status not in {"free", "premium"}:
        raise HTTPException(status_code=400, detail="Subscription status must be free or premium")
    with get_connection() as db:
        db.execute("UPDATE users SET subscription_status = ? WHERE id = ?", (payload.status, user_id))
    return status(user_id)


def _features(plan: str):
    if plan == "premium":
        return [
            "Unlimited uploads",
            "Mock exams",
            "Advanced explanations",
            "Priority AI study modes",
            "Spaced repetition",
        ]
    return ["3 uploads", "Basic summaries", "Practice quizzes", "Flashcards"]

