from __future__ import annotations
from datetime import date, datetime

def readiness_score(avg_score: int, streak: int, weak_count: int, days_left: int) -> int:
    base = avg_score * 0.65 + min(streak, 14) * 2 - weak_count * 4
    if days_left <= 7:
        base -= 5
    return max(5, min(99, round(base)))

def likely_topics(notes_topics: list[str], weak_topics: list[str]) -> list[str]:
    seen = []
    for t in weak_topics + notes_topics:
        if t and t not in seen:
            seen.append(t)
    return seen[:8] or ["Core definitions", "Worked examples", "Past questions"]

def days_until(date_text: str) -> int:
    try:
        target = datetime.fromisoformat(date_text).date()
        return max(0, (target - date.today()).days)
    except Exception:
        return 30
