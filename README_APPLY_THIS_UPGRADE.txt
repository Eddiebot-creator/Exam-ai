ExamAI Production AI Upgrade

Adds:
- real JWT auth refresh tokens
- OpenAI/Gemini API integration
- streaming AI responses
- OCR note scanning
- real-time study rooms
- WebSocket tutor chat
- AI memory personalization hooks
- adaptive quiz engine
- offline caching service
- push notifications backend hooks
- analytics dashboard backend + frontend
- AI-generated flashcards
- spaced repetition system
- exam prediction AI
- production security hardening

Apply:
1. Copy backend files into your backend.
2. Add lines from backend/requirements_ADD_THESE.txt to backend/requirements.txt.
3. Add new routers to backend/main.py:
   from routes import ai_streaming, websockets, analytics, adaptive_quiz, flashcards_ai, exam_ai, ocr_notes, notifications
   from production_hardening import SecurityHeadersMiddleware, SimpleRateLimitMiddleware
   app.add_middleware(SecurityHeadersMiddleware)
   app.add_middleware(SimpleRateLimitMiddleware)
   app.include_router(ai_streaming.router)
   app.include_router(websockets.router)
   app.include_router(analytics.router)
   app.include_router(adaptive_quiz.router)
   app.include_router(flashcards_ai.router)
   app.include_router(exam_ai.router)
   app.include_router(ocr_notes.router)
   app.include_router(notifications.router)
4. If replacing current auth, rename routes/auth_jwt.py to routes/auth.py.
5. Add frontend additions into frontend/lib.
6. Add Flutter dependencies:
   web_socket_channel: ^3.0.1
   shared_preferences: ^2.3.3

Render environment:
SECRET_KEY=your_secret
OPENAI_API_KEY=optional
GEMINI_API_KEY=optional
