def detect_burnout(study_minutes_7d: int, failed_quizzes: int, late_sessions: int) -> dict:
    risk = 0.0
    if study_minutes_7d > 900:
        risk += 0.3
    if failed_quizzes >= 3:
        risk += 0.35
    if late_sessions >= 3:
        risk += 0.25
    risk = min(1.0, risk)
    if risk >= 0.7:
        advice = "Recovery mode: reduce workload today, do one light recap, and rest."
    elif risk >= 0.4:
        advice = "You may be pushing hard. Use Focus Mode and take a break after one task."
    else:
        advice = "Your rhythm looks healthy. Keep today simple and consistent."
    return {"risk": risk, "advice": advice}
