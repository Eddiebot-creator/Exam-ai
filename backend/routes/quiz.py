import json
import random

from fastapi import APIRouter, HTTPException

from database import get_connection, record_study_activity
from schemas import QuizSubmitRequest
from services.ai_service import analyze_topics

router = APIRouter(prefix="/quiz", tags=["quiz"])


@router.get("/start/{note_id}")
def start_quiz(note_id: int, mode: str = "practice", difficulty: str = "medium", limit: int = 10):
    with get_connection() as db:
        rows = db.execute(
            """
            SELECT id, question, option_a, option_b, option_c, option_d, correct_answer, explanation
            FROM questions
            WHERE note_id = ?
            """,
            (note_id,),
        ).fetchall()
    if not rows:
        raise HTTPException(status_code=404, detail="Generate MCQs before starting a quiz")
    questions = [dict(row) for row in rows if difficulty == "mixed" or row["difficulty"] == difficulty or row["difficulty"] == "medium"]
    if mode in {"random", "mock"}:
        random.shuffle(questions)
    return questions[: max(1, min(limit, 40))]


@router.post("/submit")
def submit_quiz(payload: QuizSubmitRequest):
    with get_connection() as db:
        questions = db.execute(
            "SELECT id, correct_answer FROM questions WHERE note_id = ?",
            (payload.note_id,),
        ).fetchall()
        note = db.execute("SELECT extracted_text FROM notes WHERE id = ?", (payload.note_id,)).fetchone()
        score = sum(1 for row in questions if payload.answers.get(row["id"]) == row["correct_answer"])
        total_answered = max(1, len(payload.answers))
        topics = analyze_topics(note["extracted_text"] if note else "", payload.answers)
        db.execute(
            """
            INSERT INTO quiz_results
            (user_id, note_id, score, total_questions, mode, difficulty, time_seconds, weak_topics, strong_topics)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                payload.user_id,
                payload.note_id,
                score,
                total_answered,
                payload.mode,
                payload.difficulty,
                payload.time_seconds,
                json.dumps(topics["weak_topics"]),
                json.dumps(topics["strong_topics"]),
            ),
        )
    record_study_activity(payload.user_id, payload.note_id, f"quiz:{payload.mode}", payload.time_seconds)
    return {"score": score, "total_questions": total_answered}


@router.get("/history")
def history(user_id: int = 1):
    with get_connection() as db:
        rows = db.execute(
            """
            SELECT quiz_results.*, notes.title
            FROM quiz_results
            JOIN notes ON notes.id = quiz_results.note_id
            WHERE quiz_results.user_id = ?
            ORDER BY quiz_results.id DESC
            """,
            (user_id,),
        ).fetchall()
    return [dict(row) for row in rows]
