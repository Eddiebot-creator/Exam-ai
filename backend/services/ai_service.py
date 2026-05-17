from __future__ import annotations

import json
import os
import google.generativeai as genai
import re
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)



SUMMARY_PROMPTS = {
    "short": "Create a short, sharp study summary in 6-8 bullets.",
    "detailed": "Create a detailed study guide with headings, definitions, examples, and exam reminders.",
    "exam": "Extract what is most likely to appear in an exam, including likely question angles.",
    "definitions": "Extract key definitions, formulas, names, dates, and terms as a revision glossary.",
    "likely_questions": "Generate likely exam questions with concise model-answer hints.",
    "weak_topics": "Identify difficult or weak topics and explain them in simple language.",
}


def summarize_text(text: str, mode: str = "short") -> str:
    prompt = SUMMARY_PROMPTS.get(mode, SUMMARY_PROMPTS["short"])
        if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(
                f"{prompt}\n\n{text[:18000]}"
            )
            if response and response.text:
                return response.text.strip()
        except Exception as e:
            print("Gemini summary failed:", e)

    if os.getenv("OPENAI_API_KEY"):
        from openai import OpenAI
        client = OpenAI()
        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[
                {
                    "role": "system",
                    "content": prompt,
                },
                {"role": "user", "content": text[:18000]},
            ],
        )
        return response.output_text.strip()

    sentences = re.split(r"(?<=[.!?])\s+", text)
    important = [sentence.strip() for sentence in sentences if len(sentence.split()) > 8]
    if not important:
        return text[:1200] or "No readable study text was found."
    terms = extract_terms(text)
    if mode == "definitions":
        return "\n".join(f"- {term}: Review this concept from your note." for term in terms[:12])
    if mode == "likely_questions":
        return "\n".join(f"- Explain {term} and why it matters." for term in terms[:10])
    if mode == "weak_topics":
        return "\n".join(f"- {term}: Spend extra time on this because it appears central to the note." for term in terms[:8])
    if mode == "exam":
        return "\n".join(f"- Exam focus: {sentence}" for sentence in important[:8])
    limit = 14 if mode == "detailed" else 8
    return "\n".join(f"- {sentence}" for sentence in important[:limit])


def generate_mcqs(text: str, count: int = 8, difficulty: str = "medium", mode: str = "practice") -> list[dict[str, object]]:
        if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(
                f"""
Return only valid JSON: an array of MCQ objects with keys:
question, options, correct_answer, explanation.
correct_answer must be A, B, C, or D.

Generate {count} {difficulty} {mode} MCQs from this text:
{text[:18000]}
"""
            )
            if response and response.text:
                cleaned = response.text.strip()
                cleaned = cleaned.replace("```json", "").replace("```", "").strip()
                return json.loads(cleaned)
        except Exception as e:
            print("Gemini MCQ failed:", e)

    if os.getenv("OPENAI_API_KEY"):
        from openai import OpenAI
        client = OpenAI()
        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[
                {
                    "role": "system",
                    "content": (
                        "Return only valid JSON: an array of MCQ objects with keys "
                        "question, options, correct_answer, explanation. correct_answer must be A, B, C, or D."
                    ),
                },
                {
                    "role": "user",
                    "content": f"Generate {count} {difficulty} {mode} MCQs from this text:\n{text[:18000]}",
                },
            ],
        )
        return json.loads(response.output_text)

    terms = extract_terms(text)
    questions = []
    for index, term in enumerate(terms[:count], start=1):
        questions.append(
            {
                "question": f"Which statement best describes {term}?",
                "options": [
                    f"{term} is a key concept from the uploaded note.",
                    f"{term} is unrelated to the uploaded note.",
                    f"{term} is only used for grading attendance.",
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
            "explanation": "The app turns notes into summaries, MCQs, flashcards, and quizzes.",
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
        if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content(
                f"""
You are a friendly exam coach.

NOTE:
{text[:16000]}

QUESTION:
{message}
"""
            )
            if response and response.text:
                return response.text.strip()
        except Exception as e:
            print("Gemini chat failed:", e)

    if os.getenv("OPENAI_API_KEY"):
        from openai import OpenAI
        client = OpenAI()
        response = client.responses.create(
            model="gpt-4.1-mini",
            input=[
                {
                    "role": "system",
                    "content": (
                        "You are a friendly exam coach. Answer only from the uploaded note when possible. "
                        "Explain clearly, give examples, and suggest what to revise next."
                    ),
                },
                {"role": "user", "content": f"NOTE:\n{text[:16000]}\n\nQUESTION:\n{message}"},
            ],
        )
        return response.output_text.strip()

    lower = message.lower()
    terms = extract_terms(text)
    if "likely" in lower or "question" in lower:
        return "Likely exam questions:\n" + "\n".join(f"- Explain {term} with an example." for term in terms[:6])
    if "simple" in lower or "new" in lower:
        return "Simple explanation:\n" + summarize_text(text, "short")
    if "weak" in lower:
        return summarize_text(text, "weak_topics")
    return "Here is what your note suggests:\n" + summarize_text(text, "detailed")


def analyze_topics(text: str, answers: dict[int, str] | None = None) -> dict[str, list[str]]:
    terms = extract_terms(text)
    midpoint = max(1, len(terms) // 2)
    return {
        "strong_topics": terms[:midpoint][:6],
        "weak_topics": terms[midpoint:][:6] or terms[:3],
    }


def predict_exam(text: str) -> dict[str, list[str]]:
    terms = extract_terms(text)
    if os.getenv("OPENAI_API_KEY"):
        from openai import OpenAI
        client = OpenAI()
        response = client.responses.create(
            model="gpt-4.1-mini",
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
        return json.loads(response.output_text)
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
    words = re.findall(r"\b[A-Za-z][A-Za-z\-]{4,}\b", text)
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
