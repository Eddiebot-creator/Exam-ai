
from fastapi import APIRouter,Depends,HTTPException,UploadFile,File
from sqlalchemy.orm import Session
from database import get_db,User
from security import verify_password,hash_password
from routes.auth import user_payload
import os
router=APIRouter(prefix='/profile',tags=['Profile'])
@router.put('/{user_id}')
def update_profile(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    for k in ['full_name','email','avatar_character','bio','preferred_style']:
        if k in p: setattr(u,k,p[k])
    db.commit(); db.refresh(u); return user_payload(u)
@router.put('/{user_id}/password')
def change_password(user_id:int,p:dict,db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    if not verify_password(p.get('current_password',''),u.password_hash): raise HTTPException(400,'Current password is wrong.')
    u.password_hash=hash_password(p.get('new_password','')); db.commit(); return {'ok':True}
@router.post('/{user_id}/picture')
async def picture(user_id:int,file:UploadFile=File(...),db:Session=Depends(get_db)):
    u=db.query(User).filter_by(id=user_id).first();
    if not u: raise HTTPException(404,'User not found.')
    os.makedirs('uploads/profile',exist_ok=True); path=f'uploads/profile/{user_id}_{file.filename}'; open(path,'wb').write(await file.read()); u.profile_image_url='/'+path.replace('\\', '/'); db.commit(); db.refresh(u); return user_payload(u)
