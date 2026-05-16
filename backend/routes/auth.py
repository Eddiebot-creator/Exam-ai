
from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy.orm import Session
from database import get_db,User
from security import hash_password,verify_password
router=APIRouter(prefix='/auth',tags=['Authentication'])
def user_payload(u): return {'id':u.id,'full_name':u.full_name,'email':u.email,'avatar_character':u.avatar_character,'profile_image_url':u.profile_image_url,'bio':u.bio,'biometric_enabled':u.biometric_enabled,'xp':u.xp,'level':u.level,'streak_days':u.streak_days,'exam_course':u.exam_course,'exam_date':u.exam_date,'target_score':u.target_score}
@router.post('/register')
def register(p:dict,db:Session=Depends(get_db)):
    email=p.get('email','').strip().lower()
    if not email or not p.get('password'): raise HTTPException(400,'Email and password are required.')
    if db.query(User).filter_by(email=email).first(): raise HTTPException(400,'Email already exists.')
    u=User(full_name=p.get('full_name','Student'),email=email,password_hash=hash_password(p['password'])); db.add(u); db.commit(); db.refresh(u); return user_payload(u)
@router.post('/login')
def login(p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(email=p.get('email','').strip().lower()).first()
    if not u or not verify_password(p.get('password',''),u.password_hash): raise HTTPException(401,'Invalid email or password.')
    return user_payload(u)
@router.put('/biometric/{user_id}')
def biometric(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    u.biometric_enabled=bool(p.get('enabled',True)); db.commit(); db.refresh(u); return user_payload(u)
