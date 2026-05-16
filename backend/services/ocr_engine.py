from pathlib import Path

def extract_text_from_image(image_path: str) -> str:
    try:
        from PIL import Image
        import pytesseract
        return pytesseract.image_to_string(Image.open(image_path)).strip()
    except Exception as exc:
        return f"OCR is not fully configured on this server yet. Error: {exc}"

def extract_text_from_file(file_path: str) -> str:
    suffix = Path(file_path).suffix.lower()
    if suffix in [".png", ".jpg", ".jpeg", ".webp", ".bmp"]:
        return extract_text_from_image(file_path)
    try:
        return Path(file_path).read_text(encoding="utf-8", errors="ignore")[:50000]
    except Exception:
        return "Text extraction provider needed for this file type."
