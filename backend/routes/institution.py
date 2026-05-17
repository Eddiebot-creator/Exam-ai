
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db, InstitutionCourse

router = APIRouter(prefix="/institution", tags=["Parent Lecturer Institution Layer"])

REPORTS = {}

@router.post("/lecturer/course")
def create_course(payload: dict, db: Session = Depends(get_db)):
    course_code = payload.get("course_code", "CSC301")
    course = db.query(InstitutionCourse).filter_by(course_code=course_code).first()
    if course is None:
        course = InstitutionCourse(course_code=course_code, join_code=f"{course_code}-EXAMAI")
    course.lecturer = payload.get("lecturer", "Lecturer")
    course.title = payload.get("title", "Course")
    course.materials = payload.get("materials", [])
    db.add(course)
    db.commit()
    db.refresh(course)
    return _course_payload(course)

@router.get("/lecturer/course/{course_code}")
def get_course(course_code: str, db: Session = Depends(get_db)):
    course = db.query(InstitutionCourse).filter_by(course_code=course_code).first()
    if course is None:
        return {"error": "Course not found"}
    return _course_payload(course)

@router.post("/parent-report/{user_id}")
def parent_report(user_id: int, payload: dict):
    report = {
        "user_id": user_id,
        "student": payload.get("student", "Student"),
        "week": payload.get("week", "Current week"),
        "summary": payload.get("summary", "The student completed study sessions and improved weak topics."),
        "readiness": payload.get("readiness", 75),
        "weak_topics": payload.get("weak_topics", []),
        "encouragement": "Progress is improving. The best support now is consistency, not pressure.",
    }
    REPORTS[user_id] = report
    return report

@router.get("/class-insights/{course_code}")
def class_insights(course_code: str):
    return {
        "course_code": course_code,
        "anonymized_weak_areas": ["Recursion", "Graphs", "Database normalization"],
        "recommended_lecturer_action": "Spend 20 minutes revising the top weak area before the next quiz.",
        "privacy": "Only anonymized class-wide insight is shown.",
    }

def _course_payload(course: InstitutionCourse):
    return {
        "id": course.id,
        "course_code": course.course_code,
        "lecturer": course.lecturer,
        "title": course.title,
        "materials": course.materials or [],
        "join_code": course.join_code,
        "created_at": course.created_at.isoformat() if course.created_at else None,
    }
