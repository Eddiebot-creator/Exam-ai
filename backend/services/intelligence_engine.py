
from __future__ import annotations
from datetime import datetime, timedelta
from typing import Any

def next_review_date(correct: bool, confidence: float, ease: float) -> dict[str, Any]:
    if correct:
        new_confidence = min(1.0, confidence + 0.18)
        new_ease = min(3.5, ease + 0.12)
        interval = max(1, round(new_ease * 2))
    else:
        new_confidence = max(0.1, confidence - 0.25)
        new_ease = max(1.3, ease - 0.25)
        interval = 1
    due = datetime.utcnow() + timedelta(days=interval)
    return {"confidence": new_confidence, "ease": new_ease, "interval_days": interval, "next_review_at": due.isoformat()}

def adaptive_difficulty(last_scores: list[int], weak_topics: list[str], burnout_risk: float = 0) -> dict:
    avg = sum(last_scores) / max(1, len(last_scores))
    if burnout_risk >= 0.7:
        level, reason = "easy", "Burnout risk is high, so today should rebuild confidence."
    elif avg >= 80:
        level, reason = "hard", "You are performing well, so the next quiz should challenge you."
    elif avg >= 55:
        level, reason = "medium", "You are close to mastery, so keep difficulty balanced."
    else:
        level, reason = "easy", "Scores are low, so the app should slow down and explain more."
    return {
        "difficulty": level,
        "priority_topics": weak_topics[:3] or ["Current topic"],
        "reason": reason,
        "question_mix": {"easy": 5 if level == "easy" else 2, "medium": 4 if level == "medium" else 3, "hard": 4 if level == "hard" else 1},
    }

def readiness_score(avg_score: int, weak_count: int, completed_reviews: int, days_left: int) -> int:
    score = avg_score * 0.55 + completed_reviews * 1.5 - weak_count * 5
    if days_left <= 7:
        score -= 6
    if days_left <= 2:
        score -= 8
    return max(5, min(99, round(score)))

def build_daily_mission(course: str, weak_topics: list[str], days_left: int, readiness: int) -> dict:
    topic = weak_topics[0] if weak_topics else "your next important topic"
    tasks = [
        f"Study {topic} for 25 minutes",
        "Complete 10 adaptive MCQs",
        "Review due flashcards",
        "Ask AI to explain one weak area",
    ]
    if days_left <= 3:
        tasks = [
            f"Revise {topic} for 20 minutes",
            "Take one timed exam drill",
            "Review all wrong answers",
            "Ask AI for one final summary",
        ]
    return {
        "title": f"Today, focus on {topic}",
        "course": course or "Your course",
        "days_left": days_left,
        "readiness": readiness,
        "tasks": tasks,
        "message": f"You are {readiness}% ready. Complete today's mission to move closer to your target.",
    }

def nigerian_grade_points(score: float) -> float:
    if score >= 70: return 5.0
    if score >= 60: return 4.0
    if score >= 50: return 3.0
    if score >= 45: return 2.0
    if score >= 40: return 1.0
    return 0.0

def calculate_gpa(courses: list[dict]) -> dict:
    total_units = sum(float(c.get("units", 0)) for c in courses) or 1
    total_points = sum(float(c.get("units", 0)) * nigerian_grade_points(float(c.get("score", 0))) for c in courses)
    return {"gpa": round(total_points / total_units, 2), "total_units": total_units, "scale": "5.0 Nigerian university scale"}

def generate_timetable(courses: list[dict], weak_topics: list[str], days: int = 7) -> list[dict]:
    if not courses:
        courses = [{"course": "CSC301", "topics": weak_topics or ["Recursion"]}]
    plan = []
    for day in range(1, days + 1):
        course = courses[(day - 1) % len(courses)]
        topics = course.get("topics") or weak_topics or ["General revision"]
        topic = topics[(day - 1) % len(topics)]
        plan.append({
            "day": day,
            "course": course.get("course", "Course"),
            "focus": topic,
            "blocks": [
                {"type": "recap", "minutes": 20},
                {"type": "adaptive_quiz", "minutes": 15},
                {"type": "flashcards", "minutes": 10},
            ],
        })
    return plan

def curriculum_recommendation(school: str, course: str, weak_topics: list[str]) -> dict:
    return {
        "school": school or "Your school",
        "course": course or "Your course",
        "style": "Nigerian university exam style",
        "recommended_question_types": ["definition questions", "short theory questions", "scenario-based MCQs", "past-question style drills"],
        "priority_topics": weak_topics[:5] or ["Core definitions", "Worked examples", "Likely exam theory"],
    }
