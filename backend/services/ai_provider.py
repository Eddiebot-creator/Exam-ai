import os
from typing import AsyncGenerator

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

async def generate_ai_answer(prompt: str, system: str = "You are a helpful AI study tutor.") -> str:
    if OPENAI_API_KEY:
        try:
            from openai import AsyncOpenAI
            client = AsyncOpenAI(api_key=OPENAI_API_KEY)
            res = await client.chat.completions.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
                messages=[{"role": "system", "content": system}, {"role": "user", "content": prompt}],
            )
            return res.choices[0].message.content or ""
        except Exception as exc:
            return f"AI provider error: {exc}"

    if GEMINI_API_KEY:
        try:
            import google.generativeai as genai
            genai.configure(api_key=GEMINI_API_KEY)
            model = genai.GenerativeModel(os.getenv("GEMINI_MODEL", "gemini-1.5-flash"))
            res = model.generate_content(f"{system}\n\n{prompt}")
            return res.text or ""
        except Exception as exc:
            return f"Gemini provider error: {exc}"

    return (
        "AI key not configured yet. Add OPENAI_API_KEY or GEMINI_API_KEY in Render Environment.\n\n"
        f"Prompt received: {prompt[:500]}"
    )

async def stream_ai_answer(prompt: str, system: str = "You are a helpful AI study tutor.") -> AsyncGenerator[str, None]:
    answer = await generate_ai_answer(prompt, system)
    for word in answer.split():
        yield word + " "
