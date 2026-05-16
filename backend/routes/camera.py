
from fastapi import APIRouter,UploadFile,File
from services.learning_engine import extract_text,make_summary,detect_topics
router=APIRouter(prefix='/camera',tags=['Camera / OCR'])
@router.post('/scan')
async def scan(file:UploadFile=File(...)):
    raw=await file.read(); text=extract_text(file.filename,raw); return {'text':text,'summary':make_summary(text),'topics':detect_topics(text),'actions':['explain','generate_quiz','make_flashcards']}
