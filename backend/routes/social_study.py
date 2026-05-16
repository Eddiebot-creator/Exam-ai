
from fastapi import APIRouter

router = APIRouter(prefix="/social-study", tags=["Social Accountability"])

FRIEND_GROUPS: dict[int, list[dict]] = {}
ROOM_TIMERS: dict[str, dict] = {}

@router.post("/group/{user_id}")
def create_friend_group(user_id: int, payload: dict):
    group = {
        "id": len(FRIEND_GROUPS.get(user_id, [])) + 1,
        "name": payload.get("name", "Study Friends"),
        "members": payload.get("members", []),
        "leaderboard": [],
    }
    FRIEND_GROUPS.setdefault(user_id, []).append(group)
    return group

@router.get("/groups/{user_id}")
def list_groups(user_id: int):
    return FRIEND_GROUPS.get(user_id, [])

@router.post("/room-timer/{room_id}")
def start_room_timer(room_id: str, payload: dict):
    ROOM_TIMERS[room_id] = {
        "room_id": room_id,
        "minutes": payload.get("minutes", 25),
        "status": "running",
        "participants": payload.get("participants", []),
    }
    return ROOM_TIMERS[room_id]

@router.get("/room-timer/{room_id}")
def get_room_timer(room_id: str):
    return ROOM_TIMERS.get(room_id, {"room_id": room_id, "status": "not_started"})
