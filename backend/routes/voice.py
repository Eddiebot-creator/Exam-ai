
from fastapi import APIRouter,UploadFile,File
router=APIRouter(prefix='/voice',tags=['Voice Tutor'])
@router.post('/transcribe')
async def transcribe(file:UploadFile=File(...)): return {'transcript':f'Audio file {file.filename} was received. Speech recognition provider is not configured on this deployment yet.','provider_status':'not_configured','file':file.filename}
@router.post('/speak')
def speak(p:dict): return {'audio_url':'','text':p.get('text',''),'provider_status':'not_configured','message':'Text-to-speech is not configured on this deployment yet.'}
