
from passlib.context import CryptContext
pwd_context=CryptContext(schemes=['bcrypt'],deprecated='auto')
def hash_password(password:str)->str: return pwd_context.hash(password)
def verify_password(password:str, hashed:str)->bool: return bool(hashed) and pwd_context.verify(password, hashed)
