
def diagnose_weak_area(topic: str, answers: list[dict]) -> dict:
    conceptual = 0
    application = 0
    exam_format = 0
    recall = 0

    for item in answers:
        if item.get("correct"):
            continue
        kind = item.get("kind", "conceptual")
        if kind == "conceptual":
            conceptual += 1
        elif kind == "application":
            application += 1
        elif kind == "exam_format":
            exam_format += 1
        else:
            recall += 1

    gaps = {
        "conceptual_gap": conceptual,
        "application_gap": application,
        "exam_format_gap": exam_format,
        "recall_gap": recall,
    }

    biggest = max(gaps, key=gaps.get)
    prescriptions = {
        "conceptual_gap": "Teach the idea with simpler analogies before asking harder questions.",
        "application_gap": "Give worked examples and scenario-based practice.",
        "exam_format_gap": "Use past-question style drills and explain question patterns.",
        "recall_gap": "Use spaced repetition and quick active recall.",
    }

    return {
        "topic": topic,
        "gap_type": biggest,
        "scores": gaps,
        "teaching_strategy": prescriptions[biggest],
        "next_micro_lesson": f"Repair {biggest.replace('_', ' ')} in {topic}.",
    }
