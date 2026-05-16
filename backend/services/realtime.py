ROOM_MESSAGES={}
def add_message(room_id,user_id,message):
    items=ROOM_MESSAGES.setdefault(room_id,[]); items.append({'user_id':user_id,'message':message}); return items[-50:]
