from passlib.context import CryptContext
from passlib.exc import UnknownHashError

# PBKDF2 avoids Render bcrypt/passlib compatibility crashes.
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def hash_password(password: str) -> str:
    password = (password or "")[:256]
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    password = (password or "")[:256]
    hashed = hashed or ""
    if not hashed:
        return False
    try:
        return pwd_context.verify(password, hashed)
    except (UnknownHashError, ValueError, TypeError):
        # Legacy/demo rows may contain plain text such as "password".
        # Do not crash the API; just compare safely so old demo accounts can still work.
        return hashed == password
