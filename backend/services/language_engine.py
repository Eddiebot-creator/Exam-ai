
SUPPORTED_LANGUAGES = {
    "english": "English",
    "pidgin": "Nigerian Pidgin",
    "yoruba": "Yoruba",
    "igbo": "Igbo",
    "hausa": "Hausa",
    "swahili": "Swahili",
    "french": "French",
}

def language_prompt(language: str, message: str) -> str:
    lang = SUPPORTED_LANGUAGES.get(language.lower(), "English")
    return f"Answer this student in {lang}. Keep it clear, respectful, and exam-focused.\n\nStudent message:\n{message}"
