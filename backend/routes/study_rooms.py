
from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from database import get_db,StudyRoom
from services.realtime import add_message
router=APIRouter(prefix='/study-rooms',tags=['Study Rooms'])
@router.post('')
def create(p:dict,db:Session=Depends(get_db)):
    r=StudyRoom(owner_id=int(p.get('owner_id',1)),name=p.get('name','Study Room'),topic=p.get('topic','General')); db.add(r); db.commit(); db.refresh(r); return {'id':r.id,'name':r.name,'topic':r.topic}
@router.get('')
def list_rooms(db:Session=Depends(get_db)): return [{'id':r.id,'name':r.name,'topic':r.topic,'active':r.active} for r in db.query(StudyRoom).filter_by(active=True).all()]
@router.post('/{room_id}/message')
def message(room_id:int,p:dict): return {'messages':add_message(room_id,int(p.get('user_id',1)),p.get('message',''))}
