from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()
from database import init_db
from routes import ai, auth, flashcards, notes, product, progress, quiz, subscriptions

app = FastAPI(title="AI Exam Assistant API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    init_db()


@app.get("/")
def health():
    return {"status": "ok", "app": "AI Exam Assistant"}


app.include_router(auth.router)
app.include_router(notes.router)
app.include_router(ai.router)
app.include_router(quiz.router)
app.include_router(flashcards.router)
app.include_router(progress.router)
app.include_router(subscriptions.router)
app.include_router(product.router)
