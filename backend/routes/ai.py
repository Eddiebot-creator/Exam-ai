from fastapi import APIRouter, HTTPException

from database import get_connection, record_study_activity
from schemas import ChatRequest, McqRequest, NoteActionRequest
from services.ai_service import chat_with_note, generate_flashcards, generate_mcqs, summarize_text

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/summarize/{note_id}")
def summarize(note_id: int, payload: NoteActionRequest):
    note = _get_note(note_id)
    summary = summarize_text(note["extracted_text"], payload.mode)
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO summaries (note_id, user_id, mode, summary_text) VALUES (?, ?, ?, ?)",
            (note_id, payload.user_id, payload.mode, summary),
        )
    record_study_activity(payload.user_id, note_id, f"summary:{payload.mode}", 60)
    return {"id": cursor.lastrowid, "note_id": note_id, "summary_text": summary}


@router.post("/generate-mcq/{note_id}")
def mcq(note_id: int, payload: McqRequest | None = None):
    note = _get_note(note_id)
    payload = payload or McqRequest()
    count = max(3, min(payload.count, 40))
    questions = generate_mcqs(note["extracted_text"], count=count, difficulty=payload.difficulty, mode=payload.mode)
    with get_connection() as db:
        db.execute("DELETE FROM questions WHERE note_id = ?", (note_id,))
        for item in questions:
            options = item["options"]
            db.execute(
                """
                INSERT INTO questions
                (note_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation, difficulty)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    note_id,
                    item["question"],
                    options[0],
                    options[1],
                    options[2],
                    options[3],
                    item["correct_answer"],
                    item["explanation"],
                    payload.difficulty,
                ),
            )
    return {"note_id": note_id, "questions": questions, "difficulty": payload.difficulty, "mode": payload.mode}


@router.post("/generate-flashcards/{note_id}")
def flashcards(note_id: int):
    note = _get_note(note_id)
    cards = generate_flashcards(note["extracted_text"])
    with get_connection() as db:
        db.execute("DELETE FROM flashcards WHERE note_id = ?", (note_id,))
        saved_cards = []
        for item in cards:
            cursor = db.execute(
                "INSERT INTO flashcards (note_id, front_text, back_text) VALUES (?, ?, ?)",
                (note_id, item["front_text"], item["back_text"]),
            )
            saved_cards.append({**item, "id": cursor.lastrowid, "rating": "new", "priority": 2})
    return {"note_id": note_id, "flashcards": saved_cards}


@router.post("/chat-with-note/{note_id}")
def chat(note_id: int, payload: ChatRequest):
    note = _get_note(note_id)
    answer = chat_with_note(note["extracted_text"], payload.message)
    with get_connection() as db:
        db.execute(
            "INSERT INTO chat_messages (note_id, user_id, role, message) VALUES (?, ?, ?, ?)",
            (note_id, payload.user_id, "user", payload.message),
        )
        db.execute(
            "INSERT INTO chat_messages (note_id, user_id, role, message) VALUES (?, ?, ?, ?)",
            (note_id, payload.user_id, "assistant", answer),
        )
    record_study_activity(payload.user_id, note_id, "chat", 90)
    return {"note_id": note_id, "answer": answer}


@router.get("/chat-with-note/{note_id}")
def chat_history(note_id: int, user_id: int = 1):
    with get_connection() as db:
        rows = db.execute(
            """
            SELECT id, role, message, created_at
            FROM chat_messages
            WHERE note_id = ? AND user_id = ?
            ORDER BY id ASC
            """,
            (note_id, user_id),
        ).fetchall()
    return [dict(row) for row in rows]


def _get_note(note_id: int):
    with get_connection() as db:
        note = db.execute("SELECT * FROM notes WHERE id = ?", (note_id,)).fetchone()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note
