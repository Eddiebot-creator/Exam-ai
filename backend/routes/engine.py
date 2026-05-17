from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from database import get_connection
from services.learning_engine import (
    engine_dashboard,
    get_note_materials,
    process_note,
    submit_quiz,
    tutor_with_context,
)

router = APIRouter(prefix="/engine", tags=["learning-engine"])


class ProcessRequest(BaseModel):
    user_id: int = 1
    mcq_count: int = 10
    flashcard_count: int = 12


class QuizSubmitEngineRequest(BaseModel):
    user_id: int
    note_id: int
    answers: dict[int, str]
    mode: str = "practice"
    difficulty: str = "medium"
    time_seconds: int = 0


class TutorRequest(BaseModel):
    user_id: int
    message: str
    note_id: int | None = None


@router.post("/process-note/{note_id}")
def process_note_endpoint(note_id: int, payload: ProcessRequest):
    try:
        return process_note(note_id, payload.user_id, mcq_count=payload.mcq_count, flashcard_count=payload.flashcard_count)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))


@router.get("/materials/{note_id}")
def materials(note_id: int, user_id: int = 1):
    try:
        return get_note_materials(note_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))


@router.get("/quiz/start/{note_id}")
def quiz_start(note_id: int, user_id: int = 1, limit: int = 10):
    with get_connection() as db:
        rows = db.execute(
            "SELECT id, question, option_a, option_b, option_c, option_d, correct_answer, explanation FROM questions WHERE note_id = ? ORDER BY id DESC LIMIT ?",
            (note_id, max(1, min(limit, 40))),
        ).fetchall()
    if not rows:
        process_note(note_id, user_id)
        with get_connection() as db:
            rows = db.execute(
                "SELECT id, question, option_a, option_b, option_c, option_d, correct_answer, explanation FROM questions WHERE note_id = ? ORDER BY id DESC LIMIT ?",
                (note_id, max(1, min(limit, 40))),
            ).fetchall()
    return [dict(row) for row in rows]


@router.post("/quiz/submit")
def quiz_submit(payload: QuizSubmitEngineRequest):
    return submit_quiz(payload.user_id, payload.note_id, payload.answers, payload.mode, payload.difficulty, payload.time_seconds)


@router.get("/dashboard/{user_id}")
def dashboard(user_id: int):
    return engine_dashboard(user_id)


@router.post("/tutor")
def tutor(payload: TutorRequest):
    return tutor_with_context(payload.user_id, payload.message, payload.note_id)
