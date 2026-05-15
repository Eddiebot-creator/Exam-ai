import json
from datetime import date, timedelta
from typing import Any

from database import get_connection, record_study_activity
from services.ai_service import (
    analyze_topics,
    build_study_plan,
    chat_with_note,
    generate_flashcards,
    generate_mcqs,
    predict_exam,
    summarize_text,
)


def _as_dict(row: Any) -> dict[str, Any] | None:
    if row is None:
        return None
    return dict(row)


def _json_load(value: str | None, fallback: Any) -> Any:
    if not value:
        return fallback
    try:
        return json.loads(value)
    except Exception:
        return fallback


def _get_note(note_id: int) -> dict[str, Any]:
    with get_connection() as db:
        row = db.execute("SELECT * FROM notes WHERE id = ?", (note_id,)).fetchone()
    note = _as_dict(row)
    if not note:
        raise ValueError("Note not found")
    return note


def process_note(note_id: int, user_id: int, *, mcq_count: int = 10, flashcard_count: int = 12) -> dict[str, Any]:
    """Full ExamAI engine: note -> summary -> flashcards -> MCQs -> exam prediction -> plan."""
    note = _get_note(note_id)
    text = note.get("extracted_text") or ""
    if not text.strip():
        raise ValueError("No readable note text found")

    summary = summarize_text(text, "detailed")
    exam_summary = summarize_text(text, "exam")
    cards = generate_flashcards(text, count=flashcard_count)
    questions = generate_mcqs(text, count=mcq_count, difficulty="medium", mode="practice")
    topic_analysis = analyze_topics(text, {})
    prediction = predict_exam(text)
    exam_date = (date.today() + timedelta(days=21)).isoformat()
    plan = build_study_plan(text, exam_date=exam_date, daily_minutes=45, goal="Prepare with confidence")

    with get_connection() as db:
        db.execute("DELETE FROM summaries WHERE note_id = ? AND user_id = ?", (note_id, user_id))
        summary_id = db.execute(
            "INSERT INTO summaries (note_id, user_id, mode, summary_text) VALUES (?, ?, ?, ?)",
            (note_id, user_id, "engine", summary),
        ).lastrowid
        db.execute(
            "INSERT INTO summaries (note_id, user_id, mode, summary_text) VALUES (?, ?, ?, ?)",
            (note_id, user_id, "exam", exam_summary),
        )

        db.execute("DELETE FROM flashcards WHERE note_id = ?", (note_id,))
        saved_cards = []
        for item in cards:
            card_id = db.execute(
                "INSERT INTO flashcards (note_id, front_text, back_text, priority) VALUES (?, ?, ?, ?)",
                (note_id, item["front_text"], item["back_text"], 2),
            ).lastrowid
            saved_cards.append({**item, "id": card_id})

        db.execute("DELETE FROM questions WHERE note_id = ?", (note_id,))
        saved_questions = []
        for item in questions:
            options = item.get("options") or []
            while len(options) < 4:
                options.append("Review the note again")
            qid = db.execute(
                """
                INSERT INTO questions
                (note_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation, difficulty)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    note_id,
                    item.get("question", "Review this concept"),
                    options[0], options[1], options[2], options[3],
                    item.get("correct_answer", "A"),
                    item.get("explanation", "Generated from your note."),
                    item.get("difficulty", "medium"),
                ),
            ).lastrowid
            saved_questions.append({**item, "id": qid})

        db.execute(
            "INSERT INTO study_plans (user_id, note_id, exam_date, daily_minutes, goal, plan_json) VALUES (?, ?, ?, ?, ?, ?)",
            (user_id, note_id, exam_date, 45, "Prepare with confidence", json.dumps(plan)),
        )

    record_study_activity(user_id, note_id, "engine:auto_process", 60)
    return {
        "status": "processed",
        "note_id": note_id,
        "summary_id": summary_id,
        "summary": summary,
        "exam_focus": exam_summary,
        "flashcards": saved_cards,
        "questions": saved_questions,
        "weak_topics": topic_analysis.get("weak_topics", []),
        "strong_topics": topic_analysis.get("strong_topics", []),
        "exam_prediction": prediction,
        "daily_plan": plan,
        "next_action": make_next_action(topic_analysis.get("weak_topics", []), prediction),
    }


def make_next_action(weak_topics: list[str], prediction: dict[str, Any]) -> str:
    topic = weak_topics[0] if weak_topics else (prediction.get("high_priority_concepts") or ["your most recent note"])[0]
    return f"Spend 25 minutes reviewing {topic}, then take a 10-question quiz."


def get_note_materials(note_id: int, user_id: int) -> dict[str, Any]:
    note = _get_note(note_id)
    with get_connection() as db:
        summaries = [dict(r) for r in db.execute("SELECT * FROM summaries WHERE note_id = ? AND user_id = ? ORDER BY id DESC", (note_id, user_id)).fetchall()]
        cards = [dict(r) for r in db.execute("SELECT * FROM flashcards WHERE note_id = ? ORDER BY id DESC", (note_id,)).fetchall()]
        questions = [dict(r) for r in db.execute("SELECT * FROM questions WHERE note_id = ? ORDER BY id DESC", (note_id,)).fetchall()]
        plans = [dict(r) for r in db.execute("SELECT * FROM study_plans WHERE note_id = ? AND user_id = ? ORDER BY id DESC", (note_id, user_id)).fetchall()]
    return {
        "note": {"id": note["id"], "title": note["title"], "file_name": note.get("file_name")},
        "summaries": summaries,
        "flashcards": cards,
        "questions": questions,
        "study_plans": [{**p, "plan": _json_load(p.get("plan_json"), [])} for p in plans],
    }


def submit_quiz(user_id: int, note_id: int, answers: dict[int, str], mode: str = "practice", difficulty: str = "medium", time_seconds: int = 0) -> dict[str, Any]:
    note = _get_note(note_id)
    with get_connection() as db:
        questions = [dict(r) for r in db.execute("SELECT * FROM questions WHERE note_id = ?", (note_id,)).fetchall()]
    if not questions:
        generated = process_note(note_id, user_id)
        questions = generated["questions"]

    details = []
    score = 0
    for q in questions:
        qid = int(q["id"])
        chosen = answers.get(qid) or answers.get(str(qid))
        correct = q["correct_answer"]
        ok = chosen == correct
        if ok:
            score += 1
        details.append({
            "question_id": qid,
            "question": q["question"],
            "chosen": chosen,
            "correct_answer": correct,
            "is_correct": ok,
            "explanation": q["explanation"],
        })

    topics = analyze_topics(note.get("extracted_text") or "", answers)
    with get_connection() as db:
        result_id = db.execute(
            """
            INSERT INTO quiz_results
            (user_id, note_id, score, total_questions, mode, difficulty, time_seconds, weak_topics, strong_topics)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (user_id, note_id, score, max(1, len(questions)), mode, difficulty, time_seconds, json.dumps(topics["weak_topics"]), json.dumps(topics["strong_topics"])),
        ).lastrowid
    record_study_activity(user_id, note_id, f"quiz:{mode}", time_seconds or 120)
    return {
        "result_id": result_id,
        "score": score,
        "total_questions": max(1, len(questions)),
        "percentage": round((score / max(1, len(questions))) * 100),
        "details": details,
        "weak_topics": topics["weak_topics"],
        "strong_topics": topics["strong_topics"],
        "next_action": make_next_action(topics["weak_topics"], {}),
    }


def engine_dashboard(user_id: int) -> dict[str, Any]:
    with get_connection() as db:
        user = dict(db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone() or {})
        notes = [dict(r) for r in db.execute("SELECT id, title, file_name, created_at FROM notes WHERE user_id = ? ORDER BY id DESC LIMIT 8", (user_id,)).fetchall()]
        quiz_rows = [dict(r) for r in db.execute("SELECT * FROM quiz_results WHERE user_id = ? ORDER BY id DESC", (user_id,)).fetchall()]
        due_cards = [dict(r) for r in db.execute("""
            SELECT flashcards.* FROM flashcards
            JOIN notes ON notes.id = flashcards.note_id
            WHERE notes.user_id = ?
            ORDER BY priority DESC, due_at ASC LIMIT 12
        """, (user_id,)).fetchall()]
        plan_row = db.execute("SELECT * FROM study_plans WHERE user_id = ? ORDER BY id DESC", (user_id,)).fetchone()

    total_questions = sum(int(r["total_questions"]) for r in quiz_rows) or 0
    total_score = sum(int(r["score"]) for r in quiz_rows) or 0
    average = round((total_score / total_questions) * 100) if total_questions else 0
    weak_counts: dict[str, int] = {}
    for row in quiz_rows:
        for topic in _json_load(row.get("weak_topics"), []):
            weak_counts[topic] = weak_counts.get(topic, 0) + 1
    weak_topics = sorted(weak_counts, key=weak_counts.get, reverse=True)[:6]
    plan = _json_load(plan_row["plan_json"], []) if plan_row else []
    today = plan[0:5] if plan else [
        {"task": "Upload one note", "focus": "Start your study engine", "minutes": "10"},
        {"task": "Generate MCQs", "focus": "Practice recall", "minutes": "15"},
        {"task": "Ask AI Tutor", "focus": "Clear confusion", "minutes": "10"},
    ]
    return {
        "user": user,
        "notes": notes,
        "average_score": average,
        "quiz_count": len(quiz_rows),
        "study_seconds": user.get("study_seconds", 0),
        "streak_days": user.get("streak_days", 0),
        "weak_topics": weak_topics,
        "due_flashcards": due_cards,
        "today_flow": today,
        "next_action": make_next_action(weak_topics, {}),
    }


def tutor_with_context(user_id: int, message: str, note_id: int | None = None) -> dict[str, Any]:
    with get_connection() as db:
        if note_id is None:
            note = db.execute("SELECT * FROM notes WHERE user_id = ? ORDER BY id DESC", (user_id,)).fetchone()
        else:
            note = db.execute("SELECT * FROM notes WHERE id = ? AND user_id = ?", (note_id, user_id)).fetchone()
    if not note:
        return {"answer": "Upload a note first so I can tutor you from your own material.", "source": None}
    note = dict(note)
    answer = chat_with_note(note.get("extracted_text") or "", message)
    with get_connection() as db:
        db.execute("INSERT INTO chat_messages (note_id, user_id, role, message) VALUES (?, ?, ?, ?)", (note["id"], user_id, "user", message))
        db.execute("INSERT INTO chat_messages (note_id, user_id, role, message) VALUES (?, ?, ?, ?)", (note["id"], user_id, "assistant", answer))
    record_study_activity(user_id, note["id"], "tutor:context", 90)
    return {"answer": answer, "source": {"note_id": note["id"], "title": note["title"]}}
