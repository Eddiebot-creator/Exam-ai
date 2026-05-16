
from fastapi import APIRouter
from services.offline_sync_engine import get_queue, mark_synced, queue_action

router = APIRouter(prefix="/offline-sync", tags=["Offline First Sync"])

@router.post("/queue/{user_id}")
def add_to_queue(user_id: int, payload: dict):
    return queue_action(user_id, payload.get("action_type", "unknown"), payload.get("payload", {}))

@router.get("/queue/{user_id}")
def read_queue(user_id: int):
    return {"items": get_queue(user_id)}

@router.post("/sync/{user_id}")
def sync(user_id: int):
    return mark_synced(user_id)
