from __future__ import annotations

import json
import os
import re
from typing import Any


SUMMARY_PROMPTS = {
    "short": "Create a short, sharp study summary in 6-8 bullets.",
    "detailed": "Create a detailed study guide with headings, definitions, examples, and exam reminders.",
    "exam": "Extract what is most likely to appear in an exam, including likely question angles.",
    "definitions": "Extract key definitions, formulas, names, dates, and terms as a revision glossary.",
    "likely_questions": "Generate likely exam questions with concise model-answer hints.",
    "weak_topics": "Identify difficult or weak topics and explain them in simple language.",
}


def _gemini_model():
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        return None
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        return genai.GenerativeModel(os.getenv("GEMINI_MODEL", "gemini-1.5-flash"))
    except Exception as exc:
        print("Gemini unavailable:", exc)
        return None


def _openai_client():
    if not os.getenv("OPENAI_API_KEY", "").strip():
        return None
    try:
        from openai import OpenAI

        return OpenAI()
    except Exception as exc:
        print("OpenAI unavailable:", exc)
        return None


def _parse_json_array(value: str) -> list[dict[str, Any]]:
    cleaned = value.strip().replace("```json", "").replace("```", "").strip()
    start = cleaned.find("[")
    end = cleaned.rfind("]")
    if start >= 0 and end >= start:
        cleaned = cleaned[start : end + 1]
    data = json.loads(cleaned)
    if not isinstance(data, list):
        raise ValueError("AI response was not a JSON array.")
    return [x for x in data if isinstance(x, dict)]


def summarize_text(text: str, mode: str = "short") -> str:
    prompt = SUMMARY_PROMPTS.get(mode, SUMMARY_PROMPTS["short"])
    source = (text or "").strip()

    model = _gemini_model()
    if model is not None and source:
        try:
            response = model.generate_content(f"{prompt}\n\n{source[:18000]}")
            if response and getattr(response, "text", ""):
                return response.text.strip()
        except Exception as exc:
            print("Gemini summary failed:", exc)

    client = _openai_client()
    if client is not None and source:
        try:
            response = client.responses.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
                input=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": source[:18000]},
                ],
            )
            return response.output_text.strip()
        except Exception as exc:
            print("OpenAI summary failed:", exc)

    sentences = re.split(r"(?<=[.!?])\s+", source)
    important = [sentence.strip() for sentence in sentences if len(sentence.split()) > 8]
    if not important:
        return source[:1200] or "No readable study text was found."
    terms = extract_terms(source)
    if mode == "definitions":
        return "\n".join(f"- {term}: Review this concept from your note." for term in terms[:12])
    if mode == "likely_questions":
        return "\n".join(f"- Explain {term} and why it matters." for term in terms[:10])
    if mode == "weak_topics":
        return "\n".join(f"- {term}: Spend extra time here because it appears central to the note." for term in terms[:8])
    if mode == "exam":
        return "\n".join(f"- Exam focus: {sentence}" for sentence in important[:8])
    limit = 14 if mode == "detailed" else 8
    return "\n".join(f"- {sentence}" for sentence in important[:limit])


def generate_mcqs(text: str, count: int = 8, difficulty: str = "medium", mode: str = "practice") -> list[dict[str, Any]]:
    source = (text or "").strip()
    request = (
        "Return only valid JSON: an array of MCQ objects with keys "
        "question, options, correct_answer, explanation. options must contain exactly four strings. "
        "correct_answer must be A, B, C, or D.\n\n"
        f"Generate {count} {difficulty} {mode} MCQs from this study text:\n{source[:18000]}"
    )

    model = _gemini_model()
    if model is not None and source:
        try:
            response = model.generate_content(request)
            if response and getattr(response, "text", ""):
                questions = _parse_json_array(response.text)
                if questions:
                    return _clean_mcqs(questions, difficulty)[:count]
        except Exception as exc:
            print("Gemini MCQ failed:", exc)

    client = _openai_client()
    if client is not None and source:
        try:
            response = client.responses.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
                input=[
                    {"role": "system", "content": "You generate exam-ready MCQs and return only JSON."},
                    {"role": "user", "content": request},
                ],
            )
            questions = _parse_json_array(response.output_text)
            if questions:
                return _clean_mcqs(questions, difficulty)[:count]
        except Exception as exc:
            print("OpenAI MCQ failed:", exc)

    return _local_mcqs(source, count, difficulty)


def _clean_mcqs(questions: list[dict[str, Any]], difficulty: str) -> list[dict[str, Any]]:
    cleaned = []
    for item in questions:
        options = item.get("options") or []
        if not isinstance(options, list) or len(options) < 4:
            continue
        answer = str(item.get("correct_answer", "A")).strip().upper()[:1]
        if answer not in {"A", "B", "C", "D"}:
            answer = "A"
        cleaned.append(
            {
                "question": str(item.get("question") or "What is the best answer?").strip(),
                "options": [str(x).strip() for x in options[:4]],
                "correct_answer": answer,
                "explanation": str(item.get("explanation") or "Review this concept in your note.").strip(),
                "difficulty": difficulty,
            }
        )
    return cleaned


def _local_mcqs(text: str, count: int, difficulty: str) -> list[dict[str, Any]]:
    terms = extract_terms(text)
    questions = []
    for term in terms[:count]:
        questions.append(
            {
                "question": f"Which statement best describes {term}?",
                "options": [
                    f"{term} is a key concept from the uploaded note.",
                    f"{term} is unrelated to the uploaded note.",
                    f"{term} is only used for attendance tracking.",
                    f"{term} is a file storage provider.",
                ],
                "correct_answer": "A",
                "explanation": f"The note identifies {term} as part of the study material. Difficulty: {difficulty}.",
                "difficulty": difficulty,
            }
        )
    return questions or [
        {
            "question": "What should you do after uploading notes?",
            "options": ["Generate study materials", "Delete the note", "Ignore the summary", "Close the app"],
            "correct_answer": "A",
            "explanation": "ExamAI turns notes into summaries, MCQs, flashcards, and tutor context.",
            "difficulty": difficulty,
        }
    ]


def generate_flashcards(text: str, count: int = 10) -> list[dict[str, str]]:
    terms = extract_terms(text)
    return [
        {
            "front_text": term,
            "back_text": f"Review how {term} is explained in your uploaded note.",
        }
        for term in terms[:count]
    ]


def chat_with_note(text: str, message: str) -> str:
    note = (text or "").strip()
    question = (message or "").strip()
    prompt = (
        "You are a friendly exam coach. Answer from the note when possible, explain clearly, "
        "give one example, and end with one tiny practice task.\n\n"
        f"NOTE:\n{note[:16000]}\n\nQUESTION:\n{question}"
    )

    model = _gemini_model()
    if model is not None and note:
        try:
            response = model.generate_content(prompt)
            if response and getattr(response, "text", ""):
                return response.text.strip()
        except Exception as exc:
            print("Gemini chat failed:", exc)

    client = _openai_client()
    if client is not None and note:
        try:
            response = client.responses.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
                input=[
                    {"role": "system", "content": "You are a patient, exam-focused study tutor."},
                    {"role": "user", "content": prompt},
                ],
            )
            return response.output_text.strip()
        except Exception as exc:
            print("OpenAI chat failed:", exc)

    lower = question.lower()
    terms = extract_terms(note)
    if "likely" in lower or "question" in lower or "mcq" in lower:
        return "Likely exam questions:\n" + "\n".join(f"- Explain {term} with an example." for term in terms[:6])
    if "simple" in lower or "new" in lower or "12" in lower:
        return "Simple explanation:\n" + summarize_text(note, "short")
    if "weak" in lower or "struggle" in lower:
        return summarize_text(note, "weak_topics")
    return "Here is what your note suggests:\n" + summarize_text(note, "detailed")


def analyze_topics(text: str, answers: dict[int, str] | None = None) -> dict[str, list[str]]:
    terms = extract_terms(text)
    midpoint = max(1, len(terms) // 2)
    return {
        "strong_topics": terms[:midpoint][:6],
        "weak_topics": terms[midpoint:][:6] or terms[:3],
    }


def predict_exam(text: str) -> dict[str, list[str]]:
    terms = extract_terms(text)
    client = _openai_client()
    if client is not None and text:
        try:
            response = client.responses.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
                input=[
                    {
                        "role": "system",
                        "content": (
                            "Return valid JSON with keys likely_topics, likely_theory_questions, "
                            "likely_mcqs, high_priority_concepts. Each value must be an array of strings."
                        ),
                    },
                    {"role": "user", "content": text[:16000]},
                ],
            )
            parsed = json.loads(response.output_text)
            if isinstance(parsed, dict):
                return parsed
        except Exception as exc:
            print("OpenAI exam prediction failed:", exc)
    return {
        "likely_topics": terms[:8],
        "likely_theory_questions": [f"Explain {term} and its importance." for term in terms[:5]],
        "likely_mcqs": [f"What best describes {term}?" for term in terms[5:10]],
        "high_priority_concepts": terms[:4],
    }


def build_study_plan(text: str, exam_date: str, daily_minutes: int, goal: str) -> list[dict[str, str]]:
    terms = extract_terms(text)[:14] or ["Review notes", "Practice questions", "Revise weak topics"]
    tasks = [
        "Read and summarize",
        "Learn key definitions",
        "Practice MCQs",
        "Review weak topics",
        "Flashcard recall",
        "Mock exam",
        "Final revision",
    ]
    return [
        {
            "day": f"Day {index + 1}",
            "focus": terms[index % len(terms)],
            "task": tasks[index % len(tasks)],
            "minutes": str(daily_minutes),
            "goal": goal,
            "exam_date": exam_date,
        }
        for index in range(14)
    ]


def extract_terms(text: str) -> list[str]:
    words = re.findall(r"\b[A-Za-z][A-Za-z\-]{4,}\b", text or "")
    stop_words = {
        "about",
        "after",
        "before",
        "could",
        "should",
        "their",
        "there",
        "these",
        "those",
        "which",
        "would",
    }
    seen = set()
    terms = []
    for word in words:
        lowered = word.lower()
        if lowered in stop_words or lowered in seen:
            continue
        seen.add(lowered)
        terms.append(word.capitalize())
    return terms


def simple_summary(text: str, max_chars: int = 900) -> str:
    cleaned = " ".join((text or "").split())
    if not cleaned:
        return "No content available yet."
    if len(cleaned) <= max_chars:
        return cleaned
    return cleaned[:max_chars].rsplit(" ", 1)[0] + "..."
