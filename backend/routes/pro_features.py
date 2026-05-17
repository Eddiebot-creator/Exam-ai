from __future__ import annotations

import json
from datetime import date, timedelta

from fastapi import APIRouter
from pydantic import BaseModel

from database import get_connection
from services.ai_service import simple_summary

router = APIRouter(prefix="/pro", tags=["pro_features"])


class TutorProRequest(BaseModel):
    user_id: int
    note_id: int | None = None
    message: str
    mode: str = "step_by_step"


class CommunityPostRequest(BaseModel):
    user_id: int
    title: str
    body: str
    group_name: str = "General Study Room"


class MarketplaceItemRequest(BaseModel):
    user_id: int
    title: str
    type: str = "Study Pack"
    price: str = "Free"
    description: str = "Premium student resource"


def _note_text(note_id: int | None) -> str:
    if not note_id:
        return ""
    with get_connection() as db:
        row = db.execute("SELECT extracted_text FROM notes WHERE id = ?", (note_id,)).fetchone()
    return row["extracted_text"] if row else ""


@router.post("/ai-tutor")
def ai_tutor_pro(payload: TutorProRequest):
    context = _note_text(payload.note_id)
    focus = context[:1600] if context else "No note context selected yet."
    mode_label = payload.mode.replace("_", " ").title()
    answer = (
        f"{mode_label} Tutor Response\n\n"
        f"1. Main idea: {simple_summary(focus or payload.message, 'short')}\n\n"
        f"2. Step-by-step explanation:\n"
        f"- Identify the key terms in the question.\n"
        f"- Connect them to your uploaded note or course topic.\n"
        f"- Break the concept into smaller exam-ready points.\n"
        f"- Practice with one similar question.\n\n"
        f"3. Your question: {payload.message}\n\n"
        f"4. Exam tip: Turn this into a short definition, one example, and one application point."
    )
    return {
        "mode": payload.mode,
        "answer": answer,
        "voice_script": answer[:900],
        "image_upload_status": "ready_for_ocr_pipeline",
        "note_context_used": bool(context),
    }


@router.get("/war-room/{user_id}")
def war_room(user_id: int):
    with get_connection() as db:
        user = db.execute("SELECT streak_days, study_seconds FROM users WHERE id = ?", (user_id,)).fetchone()
        weak_rows = db.execute(
            "SELECT weak_topics FROM quiz_results WHERE user_id = ? ORDER BY id DESC LIMIT 5",
            (user_id,),
        ).fetchall()
    weak_topics: list[str] = []
    for row in weak_rows:
        weak_topics.extend([part.strip() for part in (row["weak_topics"] or "").split(",") if part.strip()])
    return {
        "exam_name": "Next Major Exam",
        "exam_date": str(date.today() + timedelta(days=18)),
        "days_left": 18,
        "streak_days": int(user["streak_days"] if user else 0),
        "study_minutes_today": round((int(user["study_seconds"] if user else 0) / 60) % 180),
        "readiness": 64,
        "weak_topics": weak_topics[:6] or ["Linked lists", "Database keys", "Time complexity"],
        "daily_tasks": [
            "Review one weak topic for 25 minutes",
            "Complete 10 MCQs in mock mode",
            "Revise 15 flashcards",
            "Ask AI Tutor Pro for one step-by-step explanation",
        ],
    }


@router.get("/daily-challenges/{user_id}")
def daily_challenges(user_id: int):
    return [
        {"title": "10-question sprint", "xp": 50, "status": "open"},
        {"title": "Revise 15 flashcards", "xp": 35, "status": "open"},
        {"title": "Explain one topic aloud", "xp": 25, "status": "open"},
    ]


@router.get("/leaderboard")
def leaderboard():
    with get_connection() as db:
        rows = db.execute(
            "SELECT full_name, study_seconds, streak_days FROM users ORDER BY study_seconds DESC, streak_days DESC LIMIT 20"
        ).fetchall()
    data = [dict(row) for row in rows]
    if not data:
        data = [
            {"full_name": "Study Partner", "study_seconds": 0, "streak_days": 0},
            {"full_name": "New Classmate", "study_seconds": 0, "streak_days": 0},
        ]
    return data


@router.get("/community/posts")
def community_posts(user_id: int = 1):
    with get_connection() as db:
        rows = db.execute("SELECT * FROM community_posts ORDER BY id DESC LIMIT 30").fetchall()
    data = [dict(row) for row in rows]
    if not data:
        data = [
            {"id": 1, "user_id": user_id, "group_name": "Data Structures", "title": "Binary search explanation", "body": "Can someone explain why binary search is O(log n)?"},
            {"id": 2, "user_id": user_id, "group_name": "Exam War Room", "title": "Mock exam tonight", "body": "Join the 8pm revision sprint."},
        ]
    return data


@router.post("/community/posts")
def create_community_post(payload: CommunityPostRequest):
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO community_posts (user_id, group_name, title, body) VALUES (?, ?, ?, ?)",
            (payload.user_id, payload.group_name, payload.title, payload.body),
        )
    return {"id": cursor.lastrowid, **payload.model_dump()}


@router.get("/marketplace/items")
def marketplace_items():
    with get_connection() as db:
        rows = db.execute("SELECT * FROM marketplace_items ORDER BY id DESC LIMIT 30").fetchall()
    data = [dict(row) for row in rows]
    if not data:
        data = [
            {"id": 1, "title": "Data Structures Study Pack", "type": "Study Pack", "price": "₦1,500", "description": "Summaries, MCQs, and flashcards for linked lists, trees, stacks, and queues."},
            {"id": 2, "title": "1-on-1 Exam Tutoring", "type": "Tutoring", "price": "₦3,000/hr", "description": "Book a top student tutor for live revision."},
            {"id": 3, "title": "Operating Systems Flashcards", "type": "Flashcards", "price": "₦800", "description": "Spaced repetition cards for OS concepts."},
        ]
    return data


@router.post("/marketplace/items")
def create_marketplace_item(payload: MarketplaceItemRequest):
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO marketplace_items (user_id, title, type, price, description) VALUES (?, ?, ?, ?, ?)",
            (payload.user_id, payload.title, payload.type, payload.price, payload.description),
        )
    return {"id": cursor.lastrowid, **payload.model_dump()}


@router.get("/teacher/dashboard/{teacher_id}")
def teacher_dashboard(teacher_id: int):
    with get_connection() as db:
        classes = [dict(row) for row in db.execute("SELECT * FROM classes WHERE teacher_id = ?", (teacher_id,)).fetchall()]
        assignments = [dict(row) for row in db.execute("SELECT * FROM assignments ORDER BY id DESC LIMIT 20").fetchall()]
        students = db.execute("SELECT COUNT(*) AS count FROM users").fetchone()["count"]
        quiz_rows = db.execute("SELECT score, total_questions FROM quiz_results WHERE total_questions > 0").fetchall()
    if quiz_rows:
        avg = round(sum((row["score"] / row["total_questions"]) * 100 for row in quiz_rows) / len(quiz_rows))
    else:
        avg = 0
    return {"classes": classes, "assignments": assignments, "students": students, "average_score": avg}


@router.get("/offline-pack/{user_id}")
def offline_pack(user_id: int):
    with get_connection() as db:
        notes = db.execute("SELECT COUNT(*) AS count FROM notes WHERE user_id = ?", (user_id,)).fetchone()["count"]
        cards = db.execute("SELECT COUNT(*) AS count FROM flashcards WHERE note_id IN (SELECT id FROM notes WHERE user_id = ?)", (user_id,)).fetchone()["count"]
    return {"saved_notes": notes, "saved_flashcards": cards, "downloaded_summaries": notes, "sync_status": "Ready"}


@router.get("/notifications/{user_id}")
def notifications(user_id: int):
    return [
        {"title": "Daily Challenge", "message": "Complete 10 MCQs today to keep your streak."},
        {"title": "Exam Countdown", "message": "18 days left. Review weak topics first."},
        {"title": "Flashcard Reminder", "message": "15 flashcards are ready for review."},
    ]


@router.get("/career-hub/{user_id}")
def career_hub(user_id: int):
    return {
        "career_level": "Starter Portfolio",
        "internships": [
            {"title": "Software Engineering Intern", "company": "Remote Startup"},
            {"title": "Data Analyst Intern", "company": "Campus Partner"},
        ],
        "scholarships": [
            {"title": "STEM Excellence Scholarship", "deadline": "30 days"},
            {"title": "Future Builders Grant", "deadline": "45 days"},
        ],
        "cv_sections": ["Education", "Skills", "Projects", "Certifications", "Achievements"],
    }
