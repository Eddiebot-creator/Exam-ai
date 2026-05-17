from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database import get_db, User
from security import hash_password, verify_password

router = APIRouter(prefix='/auth', tags=['Authentication'])

def user_payload(u):
    return {
        'id': u.id,
        'full_name': getattr(u, 'full_name', 'Student') or 'Student',
        'email': getattr(u, 'email', ''),
        'avatar_character': getattr(u, 'avatar_character', 'robot') or 'robot',
        'profile_image_url': getattr(u, 'profile_image_url', '') or '',
        'bio': getattr(u, 'bio', '') or '',
        'biometric_enabled': bool(getattr(u, 'biometric_enabled', False)),
        'xp': int(getattr(u, 'xp', 0) or 0),
        'level': int(getattr(u, 'level', 1) or 1),
        'streak_days': int(getattr(u, 'streak_days', 0) or 0),
        'exam_course': getattr(u, 'exam_course', '') or '',
        'exam_date': getattr(u, 'exam_date', '') or '',
        'target_score': int(getattr(u, 'target_score', 80) or 80),
    }

@router.post('/register')
def register(p: dict, db: Session = Depends(get_db)):
    email = (p.get('email') or '').strip().lower()
    password = p.get('password') or ''
    full_name = (p.get('full_name') or p.get('name') or 'Student').strip() or 'Student'

    if not email or not password:
        raise HTTPException(400, 'Email and password are required.')
    if len(password) < 4:
        raise HTTPException(400, 'Password must be at least 4 characters.')

    existing = db.query(User).filter_by(email=email).first()
    if existing:
        # If the user exists, do not crash. Let the user login instead.
        raise HTTPException(400, 'Email already exists. Please login instead.')

    try:
        u = User(full_name=full_name, email=email, password_hash=hash_password(password))
        db.add(u)
        db.commit()
        db.refresh(u)
        return user_payload(u)
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(500, f'Registration database error: {str(exc)}')

@router.post('/login')
def login(p: dict, db: Session = Depends(get_db)):
    email = (p.get('email') or '').strip().lower()
    password = p.get('password') or ''
    u = db.query(User).filter_by(email=email).first()

    if not u:
        raise HTTPException(401, 'Invalid email or password.')

    if not verify_password(password, getattr(u, 'password_hash', '') or ''):
        raise HTTPException(401, 'Invalid email or password.')

    # Upgrade legacy plaintext/demo hashes to PBKDF2 after a successful login.
    current_hash = getattr(u, 'password_hash', '') or ''
    if not current_hash.startswith('$pbkdf2-sha256$'):
        u.password_hash = hash_password(password)
        db.commit()
        db.refresh(u)

    return user_payload(u)

@router.put('/biometric/{user_id}')
def biometric(user_id: int, p: dict, db: Session = Depends(get_db)):
    u = db.query(User).filter_by(id=user_id).first()
    if not u:
        raise HTTPException(404, 'User not found.')
    u.biometric_enabled = bool(p.get('enabled', True))
    db.commit()
    db.refresh(u)
    return user_payload(u)

@router.put('/onboarding/{user_id}')
def onboarding(user_id: int, p: dict, db: Session = Depends(get_db)):
    u = db.query(User).filter_by(id=user_id).first()
    if not u:
        raise HTTPException(404, 'User not found.')
    u.exam_course = (p.get('exam_course') or u.exam_course or '').strip()
    u.exam_date = (p.get('exam_date') or u.exam_date or '').strip()
    u.target_score = int(p.get('target_score') or u.target_score or 80)
    if p.get('preferred_style'):
        u.preferred_style = p.get('preferred_style')
    db.commit()
    db.refresh(u)
    return user_payload(u)
