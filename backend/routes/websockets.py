from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List

router = APIRouter(tags=["WebSockets"])

class ConnectionManager:
    def __init__(self):
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        await websocket.accept()
        self.rooms.setdefault(room_id, []).append(websocket)

    def disconnect(self, room_id: str, websocket: WebSocket):
        if room_id in self.rooms and websocket in self.rooms[room_id]:
            self.rooms[room_id].remove(websocket)

    async def broadcast(self, room_id: str, message: dict):
        for socket in list(self.rooms.get(room_id, [])):
            await socket.send_json(message)

manager = ConnectionManager()

@router.websocket("/ws/study-room/{room_id}")
async def study_room_socket(websocket: WebSocket, room_id: str):
    await manager.connect(room_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            await manager.broadcast(room_id, {"room_id": room_id, "type": "message", "data": data})
    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)

@router.websocket("/ws/tutor/{user_id}")
async def tutor_socket(websocket: WebSocket, user_id: str):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            question = data.get("message", "")
            await websocket.send_json({"type": "typing", "message": "AI tutor is thinking..."})
            await websocket.send_json({"type": "answer", "message": f"Let's solve this step by step: {question}"})
    except WebSocketDisconnect:
        pass
