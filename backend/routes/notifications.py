from fastapi import APIRouter, Depends
from security_jwt import get_current_user_id

router = APIRouter(prefix="/notifications", tags=["Push Notifications"])
DEVICE_TOKENS = {}

@router.post("/register-device")
def register_device(payload: dict, user_id: int = Depends(get_current_user_id)):
    token = payload.get("device_token", "")
    platform = payload.get("platform", "unknown")
    DEVICE_TOKENS.setdefault(user_id, []).append({"token": token, "platform": platform})
    return {"ok": True, "message": "Device token saved. Connect Firebase Cloud Messaging for production sending."}

@router.post("/send-test")
def send_test(payload: dict, user_id: int = Depends(get_current_user_id)):
    return {
        "ok": True,
        "queued": True,
        "title": payload.get("title", "Study reminder"),
        "body": payload.get("body", "Time for your next study mission."),
        "note": "Production push requires Firebase Admin SDK credentials.",
    }
