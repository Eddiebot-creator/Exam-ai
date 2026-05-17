from __future__ import annotations

from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TextNoteRequest(BaseModel):
    user_id: int
    title: str
    text: str


class NoteActionRequest(BaseModel):
    user_id: int = 1
    mode: str = "short"


class QuizSubmitRequest(BaseModel):
    user_id: int
    note_id: int
    answers: dict[int, str]
    mode: str = "practice"
    difficulty: str = "medium"
    time_seconds: int = 0


class ChatRequest(BaseModel):
    user_id: int
    message: str


class McqRequest(BaseModel):
    count: int = 8
    difficulty: str = "medium"
    mode: str = "practice"


class FlashcardRatingRequest(BaseModel):
    rating: str


class StudyTimeRequest(BaseModel):
    user_id: int
    note_id: int | None = None
    activity: str = "study"
    seconds: int = 0


class SubscriptionUpdateRequest(BaseModel):
    status: str


class PreferenceRequest(BaseModel):
    academic_level: str = "University"
    subject: str = "General"
    exam_type: str = "Course exam"
    study_goal: str = "Pass with confidence"
    daily_reminder: str = "18:00"
    ai_tone: str = "Step-by-step"


class PlannerRequest(BaseModel):
    user_id: int
    note_id: int | None = None
    exam_date: str
    daily_minutes: int = 45
    goal: str = "Prepare for exam"


class PaymentRequest(BaseModel):
    user_id: int
    plan: str = "premium"


class SchoolCreateRequest(BaseModel):
    teacher_id: int
    name: str


class AssignmentRequest(BaseModel):
    class_id: int
    note_id: int
    title: str
    due_date: str
