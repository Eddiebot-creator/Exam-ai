
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, OfflineAction

router = APIRouter(prefix="/offline-sync", tags=["Offline First Sync"])

@router.post("/queue/{user_id}")
def add_to_queue(user_id: int, payload: dict, db: Session = Depends(get_db)):
    item = OfflineAction(
        user_id=user_id,
        action_type=payload.get("action_type", "unknown"),
        payload=payload.get("payload", {}),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return _offline_payload(item)

@router.get("/queue/{user_id}")
def read_queue(user_id: int, db: Session = Depends(get_db)):
    items = db.query(OfflineAction).filter_by(user_id=user_id).order_by(OfflineAction.id.desc()).limit(100).all()
    return {"items": [_offline_payload(x) for x in items]}

@router.post("/sync/{user_id}")
def sync(user_id: int, db: Session = Depends(get_db)):
    items = db.query(OfflineAction).filter_by(user_id=user_id, status="queued").all()
    for item in items:
        item.status = "synced"
        item.synced_at = datetime.utcnow()
        item.result = {"ok": True}
        db.add(item)
    db.commit()
    return {"synced": len(items)}

def _offline_payload(item: OfflineAction):
    return {
        "id": item.id,
        "action_type": item.action_type,
        "payload": item.payload or {},
        "created_at": item.created_at.isoformat() if item.created_at else None,
        "synced": item.status == "synced",
        "status": item.status,
        "result": item.result or {},
    }
