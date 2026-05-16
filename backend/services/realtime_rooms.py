rooms: dict[int, list[dict]] = {}

def add_room_message(room_id: int, user_id: int, message: str) -> list[dict]:
    items = rooms.setdefault(room_id, [])
    items.append({"user_id": user_id, "message": message})
    return items[-50:]
