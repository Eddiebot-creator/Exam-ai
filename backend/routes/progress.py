import json

from fastapi import APIRouter, HTTPException

from database import get_connection, record_study_activity
from schemas import StudyTimeRequest

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/{user_id}")
def progress(user_id: int):
    with get_connection() as db:
        user = db.execute(
            """
            SELECT id, full_name, subscription_status, uploads_used, study_seconds, streak_days, last_study_date
            FROM users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        notes_count = db.execute("SELECT COUNT(*) AS total FROM notes WHERE user_id = ?", (user_id,)).fetchone()["total"]
        quiz_rows = db.execute(
            "SELECT score, total_questions, weak_topics, strong_topics FROM quiz_results WHERE user_id = ?",
            (user_id,),
        ).fetchall()
        sessions = db.execute(
            """
            SELECT activity, SUM(seconds) AS seconds, COUNT(*) AS total
            FROM study_sessions
            WHERE user_id = ?
            GROUP BY activity
            ORDER BY total DESC
            """,
            (user_id,),
        ).fetchall()

    total_quizzes = len(quiz_rows)
    total_questions = sum(row["total_questions"] for row in quiz_rows)
    total_score = sum(row["score"] for row in quiz_rows)
    average_score = round((total_score / total_questions) * 100) if total_questions else None
    weak_topics = _topic_counts(row["weak_topics"] for row in quiz_rows)
    strong_topics = _topic_counts(row["strong_topics"] for row in quiz_rows)

    return {
        "user": dict(user),
        "notes_count": notes_count,
        "quiz_count": total_quizzes,
        "average_score": average_score,
        "weak_topics": weak_topics[:6],
        "strong_topics": strong_topics[:6],
        "study_seconds": user["study_seconds"],
        "streak_days": user["streak_days"],
        "sessions": [dict(row) for row in sessions],
        "free_upload_limit": 3,
    }


@router.post("/study-time")
def study_time(payload: StudyTimeRequest):
    record_study_activity(payload.user_id, payload.note_id, payload.activity, max(0, payload.seconds))
    return {"status": "ok"}


def _topic_counts(values):
    counts = {}
    for value in values:
        if not value:
            continue
        try:
            topics = json.loads(value)
        except json.JSONDecodeError:
            topics = []
        for topic in topics:
            counts[topic] = counts.get(topic, 0) + 1
    return sorted(counts, key=counts.get, reverse=True)

