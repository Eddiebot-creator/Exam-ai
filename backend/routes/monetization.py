
from fastapi import APIRouter

router = APIRouter(prefix="/plans", tags=["Monetization Layer"])

@router.get("")
def plans():
    return {
        "free": {
            "price": 0,
            "features": ["daily mission", "note upload", "limited AI tutor", "basic quizzes", "progress tracking"],
        },
        "pro": {
            "price": "affordable monthly",
            "features": ["unlimited AI tutor", "exam prediction", "group study rooms", "parent reports", "downloadable plans"],
        },
        "school": {
            "price": "institution pricing",
            "features": ["lecturer course tools", "class insights", "course codes", "bulk content generation"],
        },
    }
