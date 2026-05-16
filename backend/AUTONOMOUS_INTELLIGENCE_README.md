
# ExamAI Autonomous Intelligence Layer

This version adds the next-stage behavior:

> Every interaction changes future behavior automatically.

## Added backend

- `services/autonomous_orchestrator.py`
- `routes/autonomous.py`
- database models:
  - `LearningEvent`
  - `ConceptMastery`
  - `AdaptiveState`
  - `KnowledgeEdge`

## New endpoints

```text
POST /autonomous/learning-event
GET  /autonomous/adaptive-home/{user_id}
GET  /autonomous/next-best-action/{user_id}
POST /autonomous/tutor-context
```

## What now happens automatically

When a student fails a topic repeatedly:

- difficulty is lowered
- tutor style changes
- spaced repetition is scheduled
- readiness score changes
- mission changes
- emotional tone changes
- exam risk changes
- study room recommendation changes
- XP/level updates

## Frontend additions

- `lib/services/autonomous_intelligence_service.dart`
- quiz submit now sends adaptive learning events
- tutor AI route now includes adaptive context
- home screen language now reflects autonomous behavior

## Run backend checks

```powershell
cd backend
python -m py_compile main.py
python -m py_compile routes\autonomous.py
python -m py_compile services\autonomous_orchestrator.py
```

## Push

```powershell
git add .
git commit -m "Add autonomous intelligence layer"
git push origin main
```
