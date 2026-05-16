
from fastapi import APIRouter

router = APIRouter(prefix="/institution", tags=["Parent Lecturer Institution Layer"])

COURSES = {}
REPORTS = {}

@router.post("/lecturer/course")
def create_course(payload: dict):
    course_code = payload.get("course_code", "CSC301")
    course = {
        "course_code": course_code,
        "lecturer": payload.get("lecturer", "Lecturer"),
        "title": payload.get("title", "Course"),
        "materials": payload.get("materials", []),
        "join_code": f"{course_code}-EXAMAI",
    }
    COURSES[course_code] = course
    return course

@router.get("/lecturer/course/{course_code}")
def get_course(course_code: str):
    return COURSES.get(course_code, {"error": "Course not found"})

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
