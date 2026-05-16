
from fastapi import APIRouter,UploadFile,File
router=APIRouter(prefix='/voice',tags=['Voice Tutor'])
@router.post('/transcribe')
async def transcribe(file:UploadFile=File(...)): return {'transcript':'Voice transcription placeholder. Connect Whisper/OpenAI/Gemini speech provider.','file':file.filename}
@router.post('/speak')
def speak(p:dict): return {'audio_url':'','text':p.get('text',''),'message':'Text-to-speech placeholder. Connect TTS provider.'}
