from __future__ import annotations

from datetime import datetime

def emotional_response(event_type: str, wrong_streak: int = 0, hour: int | None = None) -> dict:
    hour = hour if hour is not None else datetime.utcnow().hour

    if wrong_streak >= 3:
        return {
            "tone": "supportive",
            "message": "Getting several wrong in a row is normal during deep learning. It means your brain has found the exact place that needs repair.",
            "next_action": "Slow down. Do one simple example, then retry one easier question.",
            "screen_mode": "confidence_rebuild",
        }

    if hour >= 22 or hour <= 4:
        return {
            "tone": "calm",
            "message": "It is late. Do not overload yourself. One focused revision block is better than panic studying.",
            "next_action": "Review one weak topic and sleep.",
            "screen_mode": "night_exam_calm",
        }

    if event_type == "exam_near":
        return {
            "tone": "urgent_calm",
            "message": "Your exam is close. Focus only on the highest-impact topic now.",
            "next_action": "Complete today’s mission and one short quiz.",
            "screen_mode": "exam_focus",
        }

    return {
        "tone": "encouraging",
        "message": "You are building exam confidence one small session at a time.",
        "next_action": "Continue your mission.",
        "screen_mode": "normal",
    }


def belief_score(streak_days: int, average_score: int, completed_missions: int, burnout_risk: float) -> dict:
    score = round((streak_days * 4) + (average_score * 0.5) + (completed_missions * 3) - (burnout_risk * 30))
    score = max(5, min(100, score))
    if score < 40:
        state = "needs_confidence_rebuild"
        message = "You do not need more pressure. You need a smaller win today."
    elif score < 70:
        state = "building_momentum"
        message = "You are getting closer. Keep the rhythm steady."
    else:
        state = "confident"
        message = "You are building strong exam momentum."
    return {"belief_score": score, "state": state, "message": message}
