
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, Note, ChatMessage
from services.ai_service import chat_with_note, generate_mcqs, summarize_text
from services.ai_provider import generate_ai_answer
from services.learning_engine import coach_message
from services.autonomous_orchestrator import tutor_context, process_learning_event

router = APIRouter(prefix="/ai", tags=["AI Tutor"])


@router.post("/chat")
async def chat(p: dict, db: Session = Depends(get_db)):
    try:
        user_id = int(p.get("user_id", 1))
        note_id = p.get("note_id")
        msg = (p.get("message") or "").strip()
        topic = p.get("topic") or "General"
        if not msg:
            return {"answer": "Ask me one clear question and I will help you study it step by step.", "error": None}

        note = (
            db.query(Note).filter_by(id=note_id, user_id=user_id).first()
            if note_id
            else db.query(Note).filter_by(user_id=user_id).order_by(Note.id.desc()).first()
        )

        ctx = tutor_context(db, user_id, msg)
        adaptive = ctx["context"]
        focus_topic = adaptive.get("focus_topic", topic)
        tone = adaptive.get("emotional_tone", "encouraging")
        tutor_style = adaptive.get("tutor_style", "simple")
        next_action = adaptive.get("next_best_action", "Continue studying")
        readiness = adaptive.get("readiness", 50)
        exam_risk = adaptive.get("exam_risk", "normal")
        note_text = (note.extracted_text or "") if note else ""
        note_context = note_text[:500] if note_text else "No uploaded note context yet."
        weak = adaptive.get("weak_topics") or [focus_topic]
        lower = msg.lower()

        if "mcq" in lower or "quiz" in lower:
            mcqs = generate_mcqs(note_text or focus_topic, count=5, difficulty=adaptive.get("daily_mission", {}).get("difficulty", "medium"))
            answer = "Here are 5 adaptive MCQs:\n\n" + "\n\n".join(
                f"{i}. {q['question']}\nA. {q['options'][0]}\nB. {q['options'][1]}\nC. {q['options'][2]}\nD. {q['options'][3]}\nAnswer: {q.get('correct_answer', 'A')}\nWhy: {q.get('explanation', '')}"
                for i, q in enumerate(mcqs, 1)
            )
        elif "summar" in lower:
            answer = summarize_text(note_text or f"{focus_topic}. {msg}", "exam")
        elif note_text:
            answer = chat_with_note(note_text, msg)
        else:
            prompt = (
                f"Student question: {msg}\n"
                f"Course focus: {focus_topic}\n"
                f"Weak topics: {', '.join(weak)}\n"
                f"Readiness: {readiness}%\n"
                f"Tone: {tone}\n"
                "Give a practical exam-ready answer with one tiny practice task."
            )
            provider_answer = await generate_ai_answer(prompt, ctx["system_prompt"])
            if provider_answer.startswith("AI key not configured"):
                answer = _local_tutor_answer(msg, focus_topic, weak, tone, tutor_style, readiness, exam_risk, next_action, note_context)
            else:
                answer = provider_answer

        header = (
            f"{coach_message(weak)}\n\n"
            f"Readiness: {readiness}% | Risk: {exam_risk} | Style: {tutor_style.replace('_', ' ')}\n\n"
        )
        final_answer = header + answer.strip() + f"\n\nNext best action: {next_action}"

        db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="user", content=msg))
        db.add(ChatMessage(user_id=user_id, note_id=note.id if note else None, role="assistant", content=final_answer))

        process_learning_event(db, {
            "user_id": user_id,
            "event_type": "tutor_chat",
            "topic": focus_topic,
            "correct": True,
            "confidence": 0.55,
            "difficulty": "medium",
            "seconds": 60,
            "payload": {"message": msg, "source": "ai_chat"}
        })

        return {
            "answer": final_answer,
            "context_note_id": note.id if note else None,
            "adaptive_context": adaptive,
            "error": None,
        }
    except Exception as exc:
        db.rollback()
        return {
            "answer": "I hit a tutor engine issue, but I can still help. Try asking the question again in one sentence, or upload a note first so I have course context.",
            "error": str(exc),
            "adaptive_context": {},
        }


def _local_tutor_answer(msg, focus_topic, weak, tone, tutor_style, readiness, exam_risk, next_action, note_context):
    return (
        f"Let us work on {focus_topic} in a way that is useful for exams.\n\n"
        f"Your question: {msg}\n\n"
        "1. Start with the core idea. Write the definition in your own words.\n"
        "2. Connect it to one worked example, not five at once.\n"
        "3. Turn the example into a likely exam question.\n"
        "4. Test yourself immediately with one short answer.\n\n"
        f"Because your current tone is {tone.replace('_', ' ')}, I will keep the explanation {tutor_style.replace('_', ' ')} and focused.\n"
        f"Your weak-topic queue: {', '.join(weak[:4])}.\n"
        f"Note context: {note_context}"
    )


@router.get("/history/{user_id}")
def history(user_id: int, db: Session = Depends(get_db)):
    messages = (
        db.query(ChatMessage)
        .filter_by(user_id=user_id)
        .order_by(ChatMessage.id.desc())
        .limit(50)
        .all()
    )

    return [
        {
            "role": x.role,
            "content": x.content,
            "created_at": x.created_at.isoformat(),
        }
        for x in reversed(messages)
    ]
