def transcribe_audio_stub(filename: str) -> dict:
    return {
        "transcript": "Voice transcription placeholder. Connect Whisper/Gemini/OpenAI speech here.",
        "provider_needed": True,
        "file": filename,
    }

def synthesize_speech_stub(text: str) -> dict:
    return {
        "audio_url": "",
        "message": "TTS placeholder. Connect text-to-speech provider here.",
        "text": text,
    }
