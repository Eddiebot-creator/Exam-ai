from __future__ import annotations

def extract_text_from_upload(filename: str, raw_bytes: bytes | None = None, fallback_text: str = "") -> str:
    # Production: connect Tesseract, Google Vision, Azure OCR, or Gemini Vision here.
    if fallback_text:
        return fallback_text
    return f"Extracted study content from {filename}. Add OCR provider for real camera/text extraction."
