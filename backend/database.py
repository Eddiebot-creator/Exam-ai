
import os
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Boolean, Float, JSON
from sqlalchemy.orm import DeclarativeBase, sessionmaker
DATABASE_URL=os.getenv('DATABASE_URL','sqlite:///./data/examai.db')
engine=create_engine(DATABASE_URL, connect_args={'check_same_thread':False} if DATABASE_URL.startswith('sqlite') else {})
SessionLocal=sessionmaker(bind=engine, autocommit=False, autoflush=False)
class Base(DeclarativeBase): pass
class User(Base):
    __tablename__='users'; id=Column(Integer,primary_key=True); full_name=Column(String(140),default='Student'); email=Column(String(180),unique=True,index=True); password_hash=Column(String(255),default=''); avatar_character=Column(String(80),default='robot'); profile_image_url=Column(String(600),default=''); bio=Column(Text,default=''); biometric_enabled=Column(Boolean,default=False); preferred_style=Column(String(80),default='simple'); exam_course=Column(String(160),default=''); exam_date=Column(String(50),default=''); target_score=Column(Integer,default=80); xp=Column(Integer,default=0); level=Column(Integer,default=1); streak_days=Column(Integer,default=0); created_at=Column(DateTime,default=datetime.utcnow)
class Note(Base):
    __tablename__='notes'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); title=Column(String(220)); file_name=Column(String(255),default=''); file_path=Column(String(600),default=''); extracted_text=Column(Text,default=''); topics=Column(JSON,default=list); summary=Column(Text,default=''); created_at=Column(DateTime,default=datetime.utcnow)
class Flashcard(Base):
    __tablename__='flashcards'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); note_id=Column(Integer,nullable=True,index=True); topic=Column(String(160),default='General'); question=Column(Text); answer=Column(Text); mastered=Column(Boolean,default=False); ease=Column(Float,default=2.5); interval_days=Column(Integer,default=1); due_at=Column(DateTime,default=datetime.utcnow)
class Mcq(Base):
    __tablename__='mcqs'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); note_id=Column(Integer,nullable=True,index=True); topic=Column(String(160),default='General'); question=Column(Text); options=Column(JSON,default=list); answer_index=Column(Integer,default=0); explanation=Column(Text,default='')
class QuizAttempt(Base):
    __tablename__='quiz_attempts'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); mode=Column(String(80),default='practice'); score=Column(Integer,default=0); total=Column(Integer,default=0); weak_topics=Column(JSON,default=list); answers=Column(JSON,default=list); seconds_used=Column(Integer,default=0); created_at=Column(DateTime,default=datetime.utcnow)
class ProgressEvent(Base):
    __tablename__='progress_events'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); activity=Column(String(180)); note_id=Column(Integer,nullable=True); seconds=Column(Integer,default=0); xp=Column(Integer,default=0); created_at=Column(DateTime,default=datetime.utcnow)
class ChatMessage(Base):
    __tablename__='chat_messages'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); note_id=Column(Integer,nullable=True); role=Column(String(30)); content=Column(Text); created_at=Column(DateTime,default=datetime.utcnow)
class StudyMemory(Base):
    __tablename__='study_memory'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); weak_topics=Column(JSON,default=list); strong_topics=Column(JSON,default=list); repeated_mistakes=Column(JSON,default=list); preferred_style=Column(String(80),default='simple'); burnout_risk=Column(Float,default=0); ai_notes=Column(Text,default=''); updated_at=Column(DateTime,default=datetime.utcnow)
class Achievement(Base):
    __tablename__='achievements'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); key=Column(String(120)); title=Column(String(160)); unlocked=Column(Boolean,default=True); created_at=Column(DateTime,default=datetime.utcnow)
class StudyRoom(Base):
    __tablename__='study_rooms'; id=Column(Integer,primary_key=True); owner_id=Column(Integer,index=True); name=Column(String(180)); topic=Column(String(180),default='General'); active=Column(Boolean,default=True); created_at=Column(DateTime,default=datetime.utcnow)
class WellnessCheck(Base):
    __tablename__='wellness_checks'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); mood=Column(String(80)); stress=Column(Integer,default=3); note=Column(Text,default=''); created_at=Column(DateTime,default=datetime.utcnow)

class LearningEvent(Base):
    __tablename__='learning_events'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); event_type=Column(String(120)); topic=Column(String(180),default='General'); correct=Column(Boolean,default=False); confidence=Column(Float,default=0.5); difficulty=Column(String(40),default='medium'); seconds=Column(Integer,default=0); payload=Column(JSON,default=dict); created_at=Column(DateTime,default=datetime.utcnow)
class ConceptMastery(Base):
    __tablename__='concept_mastery'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); topic=Column(String(180),index=True); mastery=Column(Float,default=0.4); confidence=Column(Float,default=0.5); ease=Column(Float,default=2.5); wrong_streak=Column(Integer,default=0); right_streak=Column(Integer,default=0); difficulty=Column(String(40),default='medium'); next_review_at=Column(DateTime,default=datetime.utcnow); explanation_style=Column(String(80),default='simple'); updated_at=Column(DateTime,default=datetime.utcnow)
class AdaptiveState(Base):
    __tablename__='adaptive_state'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True,unique=True); readiness=Column(Integer,default=50); emotional_tone=Column(String(80),default='encouraging'); tutor_style=Column(String(80),default='simple'); next_best_action=Column(Text,default='Continue studying'); daily_mission=Column(JSON,default=dict); recommended_room=Column(String(180),default=''); exam_risk=Column(String(80),default='normal'); updated_at=Column(DateTime,default=datetime.utcnow)
class KnowledgeEdge(Base):
    __tablename__='knowledge_edges'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); source_topic=Column(String(180)); target_topic=Column(String(180)); relation=Column(String(80),default='prerequisite'); strength=Column(Float,default=0.5)
class InstitutionCourse(Base):
    __tablename__='institution_courses'; id=Column(Integer,primary_key=True); course_code=Column(String(80),index=True); lecturer=Column(String(180),default=''); title=Column(String(220),default=''); join_code=Column(String(80),index=True); materials=Column(JSON,default=list); created_at=Column(DateTime,default=datetime.utcnow)
class OfflineAction(Base):
    __tablename__='offline_actions'; id=Column(Integer,primary_key=True); user_id=Column(Integer,index=True); action_type=Column(String(140)); payload=Column(JSON,default=dict); status=Column(String(40),default='queued'); result=Column(JSON,default=dict); created_at=Column(DateTime,default=datetime.utcnow); synced_at=Column(DateTime,nullable=True)

SQLITE_COLUMN_MIGRATIONS={
    'users': {
        'password_hash':'password_hash VARCHAR(255) DEFAULT ""',
        'avatar_character':'avatar_character VARCHAR(80) DEFAULT "robot"',
        'profile_image_url':'profile_image_url VARCHAR(600) DEFAULT ""',
        'bio':'bio TEXT DEFAULT ""',
        'biometric_enabled':'biometric_enabled BOOLEAN DEFAULT 0',
        'preferred_style':'preferred_style VARCHAR(80) DEFAULT "simple"',
        'exam_course':'exam_course VARCHAR(160) DEFAULT ""',
        'exam_date':'exam_date VARCHAR(50) DEFAULT ""',
        'target_score':'target_score INTEGER DEFAULT 80',
        'xp':'xp INTEGER DEFAULT 0',
        'level':'level INTEGER DEFAULT 1',
        'streak_days':'streak_days INTEGER DEFAULT 0',
        'created_at':'created_at DATETIME',
    },
    'notes': {
        'file_name':'file_name VARCHAR(255) DEFAULT ""',
        'file_path':'file_path VARCHAR(600) DEFAULT ""',
        'extracted_text':'extracted_text TEXT DEFAULT ""',
        'topics':'topics JSON',
        'summary':'summary TEXT DEFAULT ""',
        'created_at':'created_at DATETIME',
    },
    'flashcards': {
        'topic':'topic VARCHAR(160) DEFAULT "General"',
        'mastered':'mastered BOOLEAN DEFAULT 0',
        'ease':'ease FLOAT DEFAULT 2.5',
        'interval_days':'interval_days INTEGER DEFAULT 1',
        'due_at':'due_at DATETIME',
    },
    'mcqs': {
        'topic':'topic VARCHAR(160) DEFAULT "General"',
        'explanation':'explanation TEXT DEFAULT ""',
    },
}

def _apply_sqlite_migrations():
    if not DATABASE_URL.startswith('sqlite'):
        return
    with engine.begin() as conn:
        for table, columns in SQLITE_COLUMN_MIGRATIONS.items():
            existing={row[1] for row in conn.exec_driver_sql(f'PRAGMA table_info({table})').fetchall()}
            if not existing:
                continue
            for name, ddl in columns.items():
                if name in existing:
                    continue
                conn.exec_driver_sql(f'ALTER TABLE {table} ADD COLUMN {ddl}')

def init_db():
    os.makedirs('data',exist_ok=True)
    os.makedirs('uploads',exist_ok=True)
    Base.metadata.create_all(bind=engine)
    _apply_sqlite_migrations()
def get_db():
    db=SessionLocal()
    try: yield db
    finally: db.close()
