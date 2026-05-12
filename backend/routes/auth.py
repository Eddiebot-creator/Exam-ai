from fastapi import APIRouter, HTTPException

from database import get_connection, is_integrity_error
from schemas import LoginRequest, RegisterRequest
from security import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
def register(payload: RegisterRequest):
    try:
        with get_connection() as db:
            cursor = db.execute(
                "INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)",
                (payload.full_name.strip(), payload.email.lower(), hash_password(payload.password)),
            )
            user_id = cursor.lastrowid
    except Exception as exc:
        if is_integrity_error(exc):
            raise HTTPException(status_code=400, detail="Email is already registered") from exc
        raise
    return {"id": user_id, "full_name": payload.full_name, "email": payload.email}


@router.post("/login")
def login(payload: LoginRequest):
    with get_connection() as db:
        user = db.execute("SELECT * FROM users WHERE email = ?", (payload.email.lower(),)).fetchone()
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return {
        "id": user["id"],
        "full_name": user["full_name"],
        "email": user["email"],
        "subscription_status": user["subscription_status"],
    }


@router.get("/profile/{user_id}")
def profile(user_id: int):
    with get_connection() as db:
        user = db.execute(
            "SELECT id, full_name, email, subscription_status, created_at FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return dict(user)
