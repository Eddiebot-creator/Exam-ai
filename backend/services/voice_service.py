def transcribe_audio_stub(filename: str) -> dict:
    return {
        "transcript": f"Audio file {filename} was received. Speech recognition is not configured on this deployment yet.",
        "provider_status": "not_configured",
        "file": filename,
    }

def synthesize_speech_stub(text: str) -> dict:
    return {
        "audio_url": "",
        "message": "Text-to-speech is not configured on this deployment yet.",
        "provider_status": "not_configured",
        "text": text,
    }
