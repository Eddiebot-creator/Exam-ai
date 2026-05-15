import os
import re
import sqlite3
from pathlib import Path
from typing import Any

from security import hash_password

try:
    import psycopg
    from psycopg.rows import dict_row
except ImportError:  # Local SQLite development does not need psycopg installed.
    psycopg = None
    dict_row = None


DATABASE_PATH = Path(os.getenv("DATABASE_PATH", "./data/app.db"))
DATABASE_URL = os.getenv("DATABASE_URL", "").strip()

IDENTITY_TABLES = {
    "users",
    "notes",
    "summaries",
    "questions",
    "flashcards",
    "quiz_results",
    "chat_messages",
    "study_sessions",
    "study_plans",
    "classes",
    "class_members",
    "assignments",
}


def using_postgres() -> bool:
    return bool(DATABASE_URL)


def get_connection() -> Any:
    if using_postgres():
        if psycopg is None:
            raise RuntimeError("DATABASE_URL is set, but psycopg is not installed. Run pip install -r requirements.txt.")
        return PostgresConnection(DATABASE_URL)

    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


class PostgresCursor:
    def __init__(self, cursor: Any, lastrowid: int | None = None) -> None:
        self.cursor = cursor
        self.lastrowid = lastrowid

    def fetchone(self) -> Any:
        return self.cursor.fetchone()

    def fetchall(self) -> list[Any]:
        return self.cursor.fetchall()


class PostgresConnection:
    def __init__(self, url: str) -> None:
        self.connection = psycopg.connect(url, row_factory=dict_row, prepare_threshold=None)

    def __enter__(self) -> "PostgresConnection":
        return self

    def __exit__(self, exc_type: Any, exc: Any, traceback: Any) -> None:
        if exc_type:
            self.connection.rollback()
        else:
            self.connection.commit()
        self.connection.close()

    def execute(self, query: str, params: tuple[Any, ...] | list[Any] | None = None) -> PostgresCursor:
        translated = _translate_query(query)
        cursor = self.connection.execute(translated, params)
        return PostgresCursor(cursor, self._lastrowid_for_insert(query))

    def executescript(self, script: str) -> None:
        for statement in [part.strip() for part in script.split(";") if part.strip()]:
            self.execute(statement)

    def _lastrowid_for_insert(self, query: str) -> int | None:
        match = re.search(r"\bINSERT\s+INTO\s+([a-z_]+)", query, re.IGNORECASE)
        if not match or match.group(1).lower() not in IDENTITY_TABLES:
            return None
        row = self.connection.execute("SELECT LASTVAL() AS id").fetchone()
        return int(row["id"]) if row else None


def _translate_query(query: str) -> str:
    translated = query.replace("?", "%s")
    translated = translated.replace("DATETIME(flashcards.due_at) <= DATETIME('now')", "flashcards.due_at <= CURRENT_TIMESTAMP")
    translated = translated.replace("DATE('now', '-1 day')", "CURRENT_DATE - INTERVAL '1 day'")
    translated = translated.replace("DATE('now')", "CURRENT_DATE")
    return translated


SQLITE_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    subscription_status TEXT NOT NULL DEFAULT 'free',
    uploads_used INTEGER NOT NULL DEFAULT 0,
    study_seconds INTEGER NOT NULL DEFAULT 0,
    streak_days INTEGER NOT NULL DEFAULT 0,
    last_study_date TEXT,
    avatar_character TEXT NOT NULL DEFAULT 'robot',
    profile_image_path TEXT,
    bio TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    file_name TEXT,
    extracted_text TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    note_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    mode TEXT NOT NULL DEFAULT 'short',
    summary_text TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (note_id) REFERENCES notes(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    note_id INTEGER NOT NULL,
    question TEXT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_answer TEXT NOT NULL,
    explanation TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'medium',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (note_id) REFERENCES notes(id)
);

CREATE TABLE IF NOT EXISTS flashcards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    note_id INTEGER NOT NULL,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    rating TEXT NOT NULL DEFAULT 'new',
    priority INTEGER NOT NULL DEFAULT 2,
    review_count INTEGER NOT NULL DEFAULT 0,
    due_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (note_id) REFERENCES notes(id)
);

CREATE TABLE IF NOT EXISTS quiz_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    note_id INTEGER NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    mode TEXT NOT NULL DEFAULT 'practice',
    difficulty TEXT NOT NULL DEFAULT 'medium',
    time_seconds INTEGER NOT NULL DEFAULT 0,
    weak_topics TEXT NOT NULL DEFAULT '',
    strong_topics TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (note_id) REFERENCES notes(id)
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    note_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (note_id) REFERENCES notes(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS study_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    note_id INTEGER,
    activity TEXT NOT NULL,
    seconds INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (note_id) REFERENCES notes(id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id INTEGER PRIMARY KEY,
    academic_level TEXT NOT NULL DEFAULT 'University',
    subject TEXT NOT NULL DEFAULT 'General',
    exam_type TEXT NOT NULL DEFAULT 'Course exam',
    study_goal TEXT NOT NULL DEFAULT 'Pass with confidence',
    daily_reminder TEXT NOT NULL DEFAULT '18:00',
    ai_tone TEXT NOT NULL DEFAULT 'Step-by-step',
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS study_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    note_id INTEGER,
    exam_date TEXT NOT NULL,
    daily_minutes INTEGER NOT NULL,
    goal TEXT NOT NULL,
    plan_json TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (note_id) REFERENCES notes(id)
);

CREATE TABLE IF NOT EXISTS classes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    teacher_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    join_code TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS class_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    class_id INTEGER NOT NULL,
    note_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    due_date TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id),
    FOREIGN KEY (note_id) REFERENCES notes(id)
);
"""


POSTGRES_SCHEMA = SQLITE_SCHEMA.replace("INTEGER PRIMARY KEY AUTOINCREMENT", "INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY").replace(
    "created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP",
    "created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP",
).replace(
    "last_study_date TEXT",
    "last_study_date DATE",
).replace(
    "updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP",
    "updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP",
).replace(
    "due_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP",
    "due_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP",
)


def _seed_demo_user(db: Any) -> None:
    existing = db.execute(
        "SELECT id FROM users WHERE email = ?", ("student@example.com",)
    ).fetchone()
    if existing:
        return
    db.execute(
        "INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)",
        ("Demo Student", "student@example.com", hash_password("password123")),
    )


def init_db() -> None:
    with get_connection() as db:
        db.executescript(POSTGRES_SCHEMA if using_postgres() else SQLITE_SCHEMA)
        _ensure_column(db, "users", "uploads_used", "INTEGER NOT NULL DEFAULT 0")
        _ensure_column(db, "users", "study_seconds", "INTEGER NOT NULL DEFAULT 0")
        _ensure_column(db, "users", "streak_days", "INTEGER NOT NULL DEFAULT 0")
        _ensure_column(db, "users", "last_study_date", "DATE" if using_postgres() else "TEXT")
        _ensure_column(db, "users", "avatar_character", "TEXT NOT NULL DEFAULT 'robot'")
        _ensure_column(db, "users", "profile_image_path", "TEXT")
        _ensure_column(db, "users", "bio", "TEXT NOT NULL DEFAULT ''")
        _ensure_column(db, "summaries", "mode", "TEXT NOT NULL DEFAULT 'short'")
        _ensure_column(db, "questions", "difficulty", "TEXT NOT NULL DEFAULT 'medium'")
        _ensure_column(db, "flashcards", "rating", "TEXT NOT NULL DEFAULT 'new'")
        _ensure_column(db, "flashcards", "priority", "INTEGER NOT NULL DEFAULT 2")
        _ensure_column(db, "flashcards", "review_count", "INTEGER NOT NULL DEFAULT 0")
        _ensure_column(db, "flashcards", "due_at", "TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP" if using_postgres() else "TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP")
        _ensure_column(db, "quiz_results", "mode", "TEXT NOT NULL DEFAULT 'practice'")
        _ensure_column(db, "quiz_results", "difficulty", "TEXT NOT NULL DEFAULT 'medium'")
        _ensure_column(db, "quiz_results", "time_seconds", "INTEGER NOT NULL DEFAULT 0")
        _ensure_column(db, "quiz_results", "weak_topics", "TEXT NOT NULL DEFAULT ''")
        _ensure_column(db, "quiz_results", "strong_topics", "TEXT NOT NULL DEFAULT ''")
        _seed_demo_user(db)


def _ensure_column(db: Any, table: str, column: str, definition: str) -> None:
    if using_postgres():
        existing = db.execute(
            """
            SELECT column_name AS name
            FROM information_schema.columns
            WHERE table_name = %s
            """,
            (table,),
        ).fetchall()
        if column not in {row["name"] for row in existing}:
            db.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")
        return

    existing = {row["name"] for row in db.execute(f"PRAGMA table_info({table})").fetchall()}
    if column not in existing:
        db.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")


def is_integrity_error(exc: Exception) -> bool:
    postgres_integrity = psycopg is not None and isinstance(exc, psycopg.IntegrityError)
    return isinstance(exc, sqlite3.IntegrityError) or postgres_integrity


def record_study_activity(user_id: int, note_id: int | None, activity: str, seconds: int = 0) -> None:
    with get_connection() as db:
        db.execute(
            "INSERT INTO study_sessions (user_id, note_id, activity, seconds) VALUES (?, ?, ?, ?)",
            (user_id, note_id, activity, seconds),
        )
        db.execute(
            """
            UPDATE users
            SET study_seconds = study_seconds + ?,
                streak_days = CASE
                    WHEN last_study_date = DATE('now') THEN streak_days
                    WHEN last_study_date = DATE('now', '-1 day') THEN streak_days + 1
                    ELSE 1
                END,
                last_study_date = DATE('now')
            WHERE id = ?
            """,
            (seconds, user_id),
        )
