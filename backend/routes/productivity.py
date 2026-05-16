from fastapi import APIRouter

router = APIRouter(prefix="/productivity", tags=["Productivity Tools"])

@router.post("/assignment-builder")
def assignment_builder(payload: dict):
    topic = payload.get("topic", "Assignment")
    return {
        "title": topic,
        "outline": ["Introduction", "Key concepts", "Examples", "Analysis", "Conclusion"],
        "schedule": ["Research today", "Draft tomorrow", "Review before submission"],
    }

@router.post("/timetable")
def timetable(payload: dict):
    subjects = payload.get("subjects", ["Main subject"])
    return [{"day": i + 1, "focus": subjects[i % len(subjects)], "minutes": 45} for i in range(7)]

@router.post("/gpa")
def gpa(payload: dict):
    courses = payload.get("courses", [])
    total_units = sum(float(c.get("units", 0)) for c in courses) or 1
    total_points = sum(float(c.get("units", 0)) * float(c.get("points", 0)) for c in courses)
    return {"gpa": round(total_points / total_units, 2)}
