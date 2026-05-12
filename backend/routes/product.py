import json
import secrets

from fastapi import APIRouter, HTTPException

from database import get_connection
from schemas import AssignmentRequest, PaymentRequest, PlannerRequest, PreferenceRequest, SchoolCreateRequest
from services.ai_service import build_study_plan, predict_exam

router = APIRouter(tags=["product"])


@router.get("/ai/exam-prediction/{note_id}")
def exam_prediction(note_id: int):
    note = _get_note(note_id)
    return predict_exam(note["extracted_text"])


@router.post("/planner/create")
def create_plan(payload: PlannerRequest):
    text = ""
    if payload.note_id:
        note = _get_note(payload.note_id)
        text = note["extracted_text"]
    plan = build_study_plan(text, payload.exam_date, payload.daily_minutes, payload.goal)
    with get_connection() as db:
        cursor = db.execute(
            """
            INSERT INTO study_plans (user_id, note_id, exam_date, daily_minutes, goal, plan_json)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (payload.user_id, payload.note_id, payload.exam_date, payload.daily_minutes, payload.goal, json.dumps(plan)),
        )
    return {"id": cursor.lastrowid, "plan": plan}


@router.get("/planner/{user_id}")
def plans(user_id: int):
    with get_connection() as db:
        rows = db.execute(
            "SELECT * FROM study_plans WHERE user_id = ? ORDER BY id DESC",
            (user_id,),
        ).fetchall()
    return [{**dict(row), "plan": json.loads(row["plan_json"])} for row in rows]


@router.get("/preferences/{user_id}")
def get_preferences(user_id: int):
    with get_connection() as db:
        row = db.execute("SELECT * FROM user_preferences WHERE user_id = ?", (user_id,)).fetchone()
    if row:
        return dict(row)
    return {"user_id": user_id, **PreferenceRequest().model_dump()}


@router.post("/preferences/{user_id}")
def save_preferences(user_id: int, payload: PreferenceRequest):
    with get_connection() as db:
        db.execute(
            """
            INSERT INTO user_preferences
            (user_id, academic_level, subject, exam_type, study_goal, daily_reminder, ai_tone)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
              academic_level = excluded.academic_level,
              subject = excluded.subject,
              exam_type = excluded.exam_type,
              study_goal = excluded.study_goal,
              daily_reminder = excluded.daily_reminder,
              ai_tone = excluded.ai_tone,
              updated_at = CURRENT_TIMESTAMP
            """,
            (
                user_id,
                payload.academic_level,
                payload.subject,
                payload.exam_type,
                payload.study_goal,
                payload.daily_reminder,
                payload.ai_tone,
            ),
        )
    return get_preferences(user_id)


@router.post("/payment/create-checkout")
def create_checkout(payload: PaymentRequest):
    return {
        "status": "demo",
        "message": "Connect Stripe, Paystack, or Flutterwave here for live payments.",
        "checkout_url": f"https://example.com/checkout?user_id={payload.user_id}&plan={payload.plan}",
    }


@router.post("/school/classes")
def create_class(payload: SchoolCreateRequest):
    code = secrets.token_hex(3).upper()
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO classes (teacher_id, name, join_code) VALUES (?, ?, ?)",
            (payload.teacher_id, payload.name, code),
        )
    return {"id": cursor.lastrowid, "name": payload.name, "join_code": code}


@router.get("/school/classes/{teacher_id}")
def teacher_classes(teacher_id: int):
    with get_connection() as db:
        rows = db.execute("SELECT * FROM classes WHERE teacher_id = ? ORDER BY id DESC", (teacher_id,)).fetchall()
    return [dict(row) for row in rows]


@router.post("/school/assignments")
def create_assignment(payload: AssignmentRequest):
    with get_connection() as db:
        cursor = db.execute(
            "INSERT INTO assignments (class_id, note_id, title, due_date) VALUES (?, ?, ?, ?)",
            (payload.class_id, payload.note_id, payload.title, payload.due_date),
        )
    return {"id": cursor.lastrowid, **payload.model_dump()}


def _get_note(note_id: int):
    with get_connection() as db:
        note = db.execute("SELECT * FROM notes WHERE id = ?", (note_id,)).fetchone()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note

