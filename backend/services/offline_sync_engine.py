
from __future__ import annotations
from datetime import datetime

SYNC_QUEUE: dict[int, list[dict]] = {}

def queue_action(user_id: int, action_type: str, payload: dict) -> dict:
    item = {
        "id": len(SYNC_QUEUE.get(user_id, [])) + 1,
        "action_type": action_type,
        "payload": payload,
        "created_at": datetime.utcnow().isoformat(),
        "synced": False,
    }
    SYNC_QUEUE.setdefault(user_id, []).append(item)
    return item

def get_queue(user_id: int) -> list[dict]:
    return SYNC_QUEUE.get(user_id, [])

def mark_synced(user_id: int) -> dict:
    for item in SYNC_QUEUE.get(user_id, []):
        item["synced"] = True
    return {"synced": len(SYNC_QUEUE.get(user_id, []))}
