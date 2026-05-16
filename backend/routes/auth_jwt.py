from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db, User
from security import hash_password, verify_password
from security_jwt import create_access_token, create_refresh_token, decode_token

router = APIRouter(prefix="/auth", tags=["Authentication JWT"])

def user_payload(user: User):
    return {
        "id": user.id,
        "full_name": user.full_name,
        "email": user.email,
        "avatar_character": user.avatar_character,
        "profile_image_url": user.profile_image_url,
        "xp": user.xp,
        "level": user.level,
        "streak_days": user.streak_days,
    }

@router.post("/register")
def register(payload: dict, db: Session = Depends(get_db)):
    email = payload.get("email", "").strip().lower()
    password = payload.get("password", "")
    if not email or not password:
        raise HTTPException(400, "Email and password are required")
    if db.query(User).filter_by(email=email).first():
        raise HTTPException(400, "Email already exists")

    user = User(full_name=payload.get("full_name", "Student"), email=email, password_hash=hash_password(password))
    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "user": user_payload(user),
        "access_token": create_access_token(str(user.id)),
        "refresh_token": create_refresh_token(str(user.id)),
        "token_type": "bearer",
    }

@router.post("/login")
def login(payload: dict, db: Session = Depends(get_db)):
    email = payload.get("email", "").strip().lower()
    password = payload.get("password", "")
    user = db.query(User).filter_by(email=email).first()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(401, "Invalid email or password")

    return {
        "user": user_payload(user),
        "access_token": create_access_token(str(user.id)),
        "refresh_token": create_refresh_token(str(user.id)),
        "token_type": "bearer",
    }

@router.post("/refresh")
def refresh(payload: dict):
    refresh_token = payload.get("refresh_token", "")
    decoded = decode_token(refresh_token, "refresh")
    user_id = decoded["sub"]
    return {
        "access_token": create_access_token(user_id),
        "refresh_token": create_refresh_token(user_id),
        "token_type": "bearer",
    }
