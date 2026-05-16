import re
from collections import Counter

STOP = {"the","and","for","with","that","this","from","into","your","you","are","was","were","will","can","has","have"}

def topics_from_text(text: str) -> list[str]:
    words = re.findall(r"[A-Za-z]{5,}", text.lower())
    counts = Counter(w for w in words if w not in STOP)
    return [w.title() for w, _ in counts.most_common(8)] or ["General"]

def summary_from_text(text: str) -> str:
    cleaned = " ".join(text.split())
    if not cleaned:
        return "No summary yet."
    return cleaned[:900] + ("..." if len(cleaned) > 900 else "")

def flashcards_from_text(user_id: int, note_id: int | None, text: str, topics: list[str]) -> list[dict]:
    topic = topics[0] if topics else "General"
    return [
        {"user_id": user_id, "note_id": note_id, "topic": topic, "question": f"What is the main idea of {topic}?", "answer": summary_from_text(text)[:240]},
        {"user_id": user_id, "note_id": note_id, "topic": topic, "question": f"Give one exam tip for {topic}.", "answer": f"Define {topic}, show an example, then practice MCQs."},
    ]

def mcqs_from_text(user_id: int, note_id: int | None, text: str, topics: list[str]) -> list[dict]:
    topic = topics[0] if topics else "General"
    return [
        {"user_id": user_id, "note_id": note_id, "topic": topic, "question": f"Which topic should you revise first?", "options": [topic, "Random topic", "None", "Skip revision"], "answer_index": 0, "explanation": f"{topic} appears important from your study material."},
        {"user_id": user_id, "note_id": note_id, "topic": topic, "question": f"What is the best way to master {topic}?", "options": ["Ignore it", "Read once only", "Practice and review mistakes", "Guess answers"], "answer_index": 2, "explanation": "Practice plus review builds long-term mastery."},
    ]
