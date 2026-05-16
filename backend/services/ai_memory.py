from __future__ import annotations
from collections import Counter
from typing import Any

def update_memory_from_quiz(existing: dict[str, Any], weak_topics: list[str], score_pct: float) -> dict[str, Any]:
    current = list(existing.get("weak_topics", []))
    combined = current + weak_topics
    counts = Counter(combined)
    return {
        "weak_topics": [x for x, _ in counts.most_common(8)],
        "burnout_risk": min(1.0, float(existing.get("burnout_risk", 0)) + (0.08 if score_pct < 50 else -0.04)),
        "preferred_style": existing.get("preferred_style", "simple"),
        "coach_message": build_coach_message([x for x, _ in counts.most_common(3)], score_pct),
    }

def build_coach_message(weak_topics: list[str], score_pct: float) -> str:
    topic = weak_topics[0] if weak_topics else "your next topic"
    if score_pct < 50:
        return f"Let’s slow down and rebuild confidence. Focus on {topic} for 20 minutes, then try 5 easier questions."
    return f"You’re improving. Spend 25 minutes on {topic}, then complete 10 MCQs to lock it in."
