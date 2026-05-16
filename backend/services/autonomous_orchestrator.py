
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from database import (
    User, StudyMemory, QuizAttempt, ProgressEvent, StudyRoom,
    LearningEvent, ConceptMastery, AdaptiveState, KnowledgeEdge
)

STYLE_BY_GAP = {
    "conceptual": "simple_analogy",
    "application": "worked_examples",
    "exam_format": "past_question_style",
    "recall": "active_recall",
}

PREREQUISITES = {
    "Graphs": ["Recursion", "Trees"],
    "Trees": ["Recursion"],
    "Dynamic Programming": ["Recursion"],
    "Database normalization": ["Tables", "Keys"],
}

def _get_or_create_state(db: Session, user_id: int) -> AdaptiveState:
    state = db.query(AdaptiveState).filter_by(user_id=user_id).first()
    if not state:
        state = AdaptiveState(user_id=user_id)
        db.add(state)
        db.commit()
        db.refresh(state)
    return state

def _get_or_create_mastery(db: Session, user_id: int, topic: str) -> ConceptMastery:
    topic = topic or "General"
    mastery = db.query(ConceptMastery).filter_by(user_id=user_id, topic=topic).first()
    if not mastery:
        mastery = ConceptMastery(user_id=user_id, topic=topic)
        db.add(mastery)
        db.commit()
        db.refresh(mastery)
    return mastery

def _get_or_create_memory(db: Session, user_id: int) -> StudyMemory:
    memory = db.query(StudyMemory).filter_by(user_id=user_id).first()
    if not memory:
        memory = StudyMemory(user_id=user_id, weak_topics=[], strong_topics=[], repeated_mistakes=[])
        db.add(memory)
        db.commit()
        db.refresh(memory)
    return memory

def _days_left(user: User | None) -> int:
    if not user or not user.exam_date:
        return 23
    try:
        return max(0, (datetime.fromisoformat(user.exam_date).date() - datetime.utcnow().date()).days)
    except Exception:
        return 23

def _difficulty_from_mastery(mastery: ConceptMastery, burnout: float) -> str:
    if burnout >= 0.7:
        return "easy"
    if mastery.mastery >= 0.78 and mastery.wrong_streak == 0:
        return "hard"
    if mastery.mastery >= 0.5:
        return "medium"
    return "easy"

def _tone(wrong_streak: int, burnout: float, days_left: int) -> str:
    if burnout >= 0.75:
        return "calm_recovery"
    if wrong_streak >= 3:
        return "confidence_rebuild"
    if days_left <= 3:
        return "urgent_but_calm"
    return "encouraging"

def _exam_risk(readiness: int, days_left: int, weak_count: int) -> str:
    if days_left <= 3 and readiness < 60:
        return "critical"
    if readiness < 50 or weak_count >= 5:
        return "high"
    if readiness < 70:
        return "medium"
    return "low"

def _mission(topic: str, difficulty: str, tone: str, days_left: int, readiness: int) -> dict:
    if tone == "calm_recovery":
        tasks = [f"Review {topic} gently for 10 minutes", "Do 3 easy questions", "Stop after one small win"]
    elif tone == "confidence_rebuild":
        tasks = [f"Relearn {topic} with a simple analogy", "Do 5 easy questions", "Review the mistake pattern"]
    elif days_left <= 3:
        tasks = [f"Revise {topic} for 20 minutes", "Do one timed drill", "Review only wrong answers"]
    else:
        tasks = [f"Study {topic} for 25 minutes", f"Do 10 {difficulty} adaptive MCQs", "Review due flashcards"]
    return {
        "focus_topic": topic,
        "difficulty": difficulty,
        "tone": tone,
        "readiness": readiness,
        "days_left": days_left,
        "tasks": tasks,
        "message": f"Focus on {topic}. You are {readiness}% ready. I adjusted today’s plan automatically.",
    }

def process_learning_event(db: Session, payload: dict) -> dict:
    user_id = int(payload.get("user_id", 1))
    event_type = payload.get("event_type", "study")
    topic = payload.get("topic", "General")
    correct = bool(payload.get("correct", False))
    confidence = float(payload.get("confidence", 0.5))
    difficulty = payload.get("difficulty", "medium")
    seconds = int(payload.get("seconds", 0))
    gap_type = payload.get("gap_type", "conceptual")

    event = LearningEvent(
        user_id=user_id,
        event_type=event_type,
        topic=topic,
        correct=correct,
        confidence=confidence,
        difficulty=difficulty,
        seconds=seconds,
        payload=payload,
    )
    db.add(event)

    mastery = _get_or_create_mastery(db, user_id, topic)

    if correct:
        mastery.right_streak += 1
        mastery.wrong_streak = 0
        mastery.mastery = min(1.0, mastery.mastery + 0.08 + (confidence * 0.03))
        mastery.confidence = min(1.0, mastery.confidence + 0.12)
        mastery.ease = min(3.5, mastery.ease + 0.08)
    else:
        mastery.wrong_streak += 1
        mastery.right_streak = 0
        mastery.mastery = max(0.05, mastery.mastery - 0.10)
        mastery.confidence = max(0.05, mastery.confidence - 0.16)
        mastery.ease = max(1.3, mastery.ease - 0.15)
        mastery.explanation_style = STYLE_BY_GAP.get(gap_type, "simple_analogy")

    review_days = 1 if not correct else max(1, round(mastery.ease * max(1, mastery.right_streak)))
    mastery.next_review_at = datetime.utcnow() + timedelta(days=review_days)
    mastery.difficulty = _difficulty_from_mastery(mastery, 0)
    mastery.updated_at = datetime.utcnow()

    memory = _get_or_create_memory(db, user_id)
    weak = list(memory.weak_topics or [])
    strong = list(memory.strong_topics or [])
    repeated = list(memory.repeated_mistakes or [])

    if mastery.mastery < 0.55 and topic not in weak:
        weak.insert(0, topic)
    if mastery.mastery >= 0.78 and topic not in strong:
        strong.insert(0, topic)
    if mastery.wrong_streak >= 2 and topic not in repeated:
        repeated.insert(0, topic)

    memory.weak_topics = weak[:8]
    memory.strong_topics = strong[:8]
    memory.repeated_mistakes = repeated[:12]
    memory.preferred_style = mastery.explanation_style
    memory.burnout_risk = min(1.0, (memory.burnout_risk or 0) + (0.08 if not correct and seconds > 120 else -0.03))
    memory.updated_at = datetime.utcnow()

    user = db.query(User).filter_by(id=user_id).first()
    days_left = _days_left(user)
    weak_count = len(memory.weak_topics or [])
    readiness = max(5, min(99, round((mastery.mastery * 60) + (len(strong) * 3) - (weak_count * 4) - (8 if days_left <= 3 else 0))))
    tone = _tone(mastery.wrong_streak, memory.burnout_risk or 0, days_left)
    next_difficulty = _difficulty_from_mastery(mastery, memory.burnout_risk or 0)
    mission = _mission(topic, next_difficulty, tone, days_left, readiness)

    room = ""
    if mastery.wrong_streak >= 3:
        room = f"{topic} confidence rebuild room"
    elif mastery.mastery < 0.45:
        room = f"{topic} peer study room"

    state = _get_or_create_state(db, user_id)
    state.readiness = readiness
    state.emotional_tone = tone
    state.tutor_style = mastery.explanation_style
    state.next_best_action = mission["tasks"][0]
    state.daily_mission = mission
    state.recommended_room = room
    state.exam_risk = _exam_risk(readiness, days_left, weak_count)
    state.updated_at = datetime.utcnow()

    # update XP/streak lightly
    if user:
        user.xp = (user.xp or 0) + (10 if correct else 3)
        user.level = max(1, (user.xp // 100) + 1)

    db.commit()

    return {
        "event_saved": True,
        "topic": topic,
        "mastery": round(mastery.mastery, 2),
        "next_difficulty": next_difficulty,
        "next_review_at": mastery.next_review_at.isoformat(),
        "emotional_tone": tone,
        "readiness": readiness,
        "exam_risk": state.exam_risk,
        "daily_mission": mission,
        "recommended_room": room,
        "tutor_style": mastery.explanation_style,
    }

def adaptive_home(db: Session, user_id: int) -> dict:
    user = db.query(User).filter_by(id=user_id).first()
    memory = _get_or_create_memory(db, user_id)
    state = _get_or_create_state(db, user_id)

    masteries = db.query(ConceptMastery).filter_by(user_id=user_id).order_by(ConceptMastery.mastery.asc()).limit(6).all()
    weak = [m.topic for m in masteries if m.mastery < 0.7] or list(memory.weak_topics or ["General revision"])
    focus = weak[0] if weak else "General revision"

    days_left = _days_left(user)
    if not state.daily_mission:
        state.daily_mission = _mission(focus, "medium", "encouraging", days_left, state.readiness or 50)
        db.commit()

    return {
        "user_id": user_id,
        "course": user.exam_course if user else "Your course",
        "days_left": days_left,
        "readiness": state.readiness,
        "focus_topic": focus,
        "weak_topics": weak,
        "strong_topics": memory.strong_topics or [],
        "emotional_tone": state.emotional_tone,
        "tutor_style": state.tutor_style,
        "next_best_action": state.next_best_action,
        "daily_mission": state.daily_mission,
        "recommended_room": state.recommended_room,
        "exam_risk": state.exam_risk,
        "mastery_graph": [
            {
                "topic": m.topic,
                "mastery": round(m.mastery, 2),
                "confidence": round(m.confidence, 2),
                "difficulty": m.difficulty,
                "next_review_at": m.next_review_at.isoformat() if m.next_review_at else None,
                "style": m.explanation_style,
            }
            for m in masteries
        ],
    }

def tutor_context(db: Session, user_id: int, question: str) -> dict:
    home = adaptive_home(db, user_id)
    return {
        "system_prompt": (
            f"You are ExamAI, a patient adaptive tutor. "
            f"Use tone={home['emotional_tone']}, style={home['tutor_style']}, "
            f"focus_topic={home['focus_topic']}, exam_risk={home['exam_risk']}. "
            f"Never overwhelm the student. Give the next best step."
        ),
        "context": home,
        "question": question,
    }
