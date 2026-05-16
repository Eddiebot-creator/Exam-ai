
import re
from collections import Counter
from datetime import datetime, date
STOP={'the','and','for','with','that','this','from','into','your','you','are','was','were','will','can','has','have','about','what'}
def extract_text(filename, content=None, fallback=''):
    if fallback: return fallback
    if content:
        try: return content.decode('utf-8',errors='ignore')[:50000]
        except Exception: pass
    return f'Extracted text placeholder from {filename}. Connect OCR/PDF parser for full production extraction.'
def detect_topics(text):
    words=re.findall(r'[A-Za-z]{5,}',text.lower()); counts=Counter(w for w in words if w not in STOP); return [w.title() for w,_ in counts.most_common(8)] or ['General']
def make_summary(text):
    clean=' '.join(text.split()); return (clean[:1000]+('...' if len(clean)>1000 else '')) if clean else 'No summary available yet.'
def make_flashcards(user_id,note_id,text,topics):
    t=topics[0] if topics else 'General'; return [{'user_id':user_id,'note_id':note_id,'topic':t,'question':f'What is the main idea of {t}?','answer':make_summary(text)[:260]},{'user_id':user_id,'note_id':note_id,'topic':t,'question':f'How can you revise {t} for exams?','answer':f'Review definitions, solve examples, then test yourself with MCQs on {t}.'}]
def make_mcqs(user_id,note_id,text,topics):
    t=topics[0] if topics else 'General'; return [{'user_id':user_id,'note_id':note_id,'topic':t,'question':f'Which topic appears most important in this note?','options':[t,'Random topic','None','Skip it'],'answer_index':0,'explanation':f'{t} appears frequently and should be revised.'},{'user_id':user_id,'note_id':note_id,'topic':t,'question':f'What is a strong revision method for {t}?','options':['Ignore mistakes','Practice and review errors','Guess answers','Read once only'],'answer_index':1,'explanation':'Practice plus correction improves mastery.'}]
def readiness(avg,weak_count,streak,days_left):
    score=avg*.65+min(streak,14)*2-weak_count*4-(5 if days_left<=7 else 0); return max(5,min(99,round(score)))
def days_until(date_text):
    try: return max(0,(datetime.fromisoformat(date_text).date()-date.today()).days)
    except Exception: return 30
def burnout(study_minutes_7d,failed_quizzes,late_sessions):
    risk=(.3 if study_minutes_7d>900 else 0)+(.35 if failed_quizzes>=3 else 0)+(.25 if late_sessions>=3 else 0); risk=min(1.0,risk); return {'risk':risk,'advice':'Recovery mode: reduce workload and rest.' if risk>=.7 else 'Keep a steady pace and take short breaks.'}
def coach_message(weak_topics):
    topic=weak_topics[0] if weak_topics else 'your next topic'; return f'Today, focus on {topic} for 25 minutes. Complete 10 MCQs to improve your weak area.'
