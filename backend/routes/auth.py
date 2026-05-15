import os
import shutil
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel, EmailStr

from database import get_connection, is_integrity_error
from schemas import LoginRequest, RegisterRequest
from security import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads")) / "profile_pictures"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    avatar_character: str | None = None
    bio: str | None = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


def _public_user(row):
    return {
        "id": row["id"],
        "full_name": row["full_name"],
        "email": row["email"],
        "subscription_status": row["subscription_status"],
        "avatar_character": row["avatar_character"] if "avatar_character" in row.keys() else "robot",
        "profile_image_path": row["profile_image_path"] if "profile_image_path" in row.keys() else None,
        "profile_image_url": f"/{row['profile_image_path']}" if "profile_image_path" in row.keys() and row["profile_image_path"] else None,
        "bio": row["bio"] if "bio" in row.keys() else "",
        "created_at": row["created_at"] if "created_at" in row.keys() else None,
    }


def _get_user_or_404(db, user_id: int):
    user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/register")
def register(payload: RegisterRequest):
    try:
        with get_connection() as db:
            cursor = db.execute(
                "INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)",
                (payload.full_name.strip(), payload.email.lower(), hash_password(payload.password)),
            )
            user_id = cursor.lastrowid
            user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    except Exception as exc:
        if is_integrity_error(exc):
            raise HTTPException(status_code=400, detail="Email is already registered") from exc
        raise
    return _public_user(user)


@router.post("/login")
def login(payload: LoginRequest):
    with get_connection() as db:
        user = db.execute("SELECT * FROM users WHERE email = ?", (payload.email.lower(),)).fetchone()
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return _public_user(user)


@router.get("/profile/{user_id}")
def profile(user_id: int):
    with get_connection() as db:
        user = _get_user_or_404(db, user_id)
    return _public_user(user)


@router.put("/profile/{user_id}")
def update_profile(user_id: int, payload: UpdateProfileRequest):
    avatar_options = {"robot", "fox", "owl", "cat", "panda", "star", "rocket"}
    with get_connection() as db:
        user = _get_user_or_404(db, user_id)
        full_name = (payload.full_name or user["full_name"]).strip()
        email = (payload.email or user["email"]).lower().strip()
        avatar = (payload.avatar_character or user["avatar_character"] or "robot").strip()
        bio = (payload.bio if payload.bio is not None else (user["bio"] or "")).strip()
        if avatar not in avatar_options:
            avatar = "robot"
        try:
            db.execute(
                """
                UPDATE users
                SET full_name = ?, email = ?, avatar_character = ?, bio = ?
                WHERE id = ?
                """,
                (full_name, email, avatar, bio, user_id),
            )
        except Exception as exc:
            if is_integrity_error(exc):
                raise HTTPException(status_code=400, detail="Email is already used by another account") from exc
            raise
        updated = _get_user_or_404(db, user_id)
    return _public_user(updated)


@router.put("/password/{user_id}")
def change_password(user_id: int, payload: ChangePasswordRequest):
    if len(payload.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")
    with get_connection() as db:
        user = _get_user_or_404(db, user_id)
        if not verify_password(payload.current_password, user["password_hash"]):
            raise HTTPException(status_code=401, detail="Current password is incorrect")
        db.execute(
            "UPDATE users SET password_hash = ? WHERE id = ?",
            (hash_password(payload.new_password), user_id),
        )
    return {"status": "ok", "message": "Password changed successfully"}


@router.post("/profile-picture/{user_id}")
def upload_profile_picture(user_id: int, file: UploadFile = File(...)):
    allowed = {"image/png", "image/jpeg", "image/jpg", "image/webp"}
    if file.content_type not in allowed:
        raise HTTPException(status_code=400, detail="Upload a PNG, JPG, JPEG, or WEBP image")
    ext = Path(file.filename or "profile.png").suffix.lower() or ".png"
    if ext not in {".png", ".jpg", ".jpeg", ".webp"}:
        ext = ".png"
    safe_name = f"user_{user_id}{ext}"
    target = UPLOAD_DIR / safe_name
    with get_connection() as db:
        _get_user_or_404(db, user_id)
        with target.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        rel_path = str(target).replace("\\", "/")
        db.execute("UPDATE users SET profile_image_path = ? WHERE id = ?", (rel_path, user_id))
        updated = _get_user_or_404(db, user_id)
    return _public_user(updated)
