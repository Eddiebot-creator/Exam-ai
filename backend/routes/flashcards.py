from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException

from database import get_connection, record_study_activity
from schemas import FlashcardRatingRequest

router = APIRouter(prefix="/flashcards", tags=["flashcards"])


@router.get("/due")
def due_cards(user_id: int = 1, note_id: int | None = None):
    query = """
        SELECT flashcards.*
        FROM flashcards
        JOIN notes ON notes.id = flashcards.note_id
        WHERE notes.user_id = ? AND DATETIME(flashcards.due_at) <= DATETIME('now')
    """
    params: list[object] = [user_id]
    if note_id is not None:
        query += " AND flashcards.note_id = ?"
        params.append(note_id)
    query += " ORDER BY priority DESC, due_at ASC"
    with get_connection() as db:
        rows = db.execute(query, params).fetchall()
    return [dict(row) for row in rows]


@router.post("/{card_id}/rate")
def rate_card(card_id: int, payload: FlashcardRatingRequest):
    schedule = {
        "hard": (1, 3),
        "medium": (3, 2),
        "easy": (7, 1),
    }
    if payload.rating not in schedule:
        raise HTTPException(status_code=400, detail="Rating must be easy, medium, or hard")
    days, priority = schedule[payload.rating]
    due_at = (datetime.utcnow() + timedelta(days=days)).isoformat(timespec="seconds")
    with get_connection() as db:
        card = db.execute("SELECT note_id FROM flashcards WHERE id = ?", (card_id,)).fetchone()
        if not card:
            raise HTTPException(status_code=404, detail="Flashcard not found")
        db.execute(
            """
            UPDATE flashcards
            SET rating = ?, priority = ?, review_count = review_count + 1, due_at = ?
            WHERE id = ?
            """,
            (payload.rating, priority, due_at, card_id),
        )
    record_study_activity(1, card["note_id"], f"flashcard:{payload.rating}", 30)
    return {"id": card_id, "rating": payload.rating, "due_at": due_at}

