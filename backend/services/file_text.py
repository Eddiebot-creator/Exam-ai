from io import BytesIO

from fastapi import UploadFile
from pypdf import PdfReader


async def extract_upload_text(file: UploadFile) -> str:
    payload = await file.read()
    name = (file.filename or "").lower()

    if name.endswith(".pdf"):
        reader = PdfReader(BytesIO(payload))
        pages = [(page.extract_text() or "") for page in reader.pages]
        return clean_text("\n".join(pages))

    return clean_text(payload.decode("utf-8", errors="ignore"))


def clean_text(text: str) -> str:
    lines = [" ".join(line.split()) for line in text.splitlines()]
    return "\n".join(line for line in lines if line).strip()

