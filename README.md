# Mizan — Financial Decision App

Mizan is a financial decision-making tool featuring a cashflow simulation engine and Gemini LLM integration to predict the impact of purchases on user liquidity, savings goals, and overall financial health.

## Tech Stack
- **Backend**: Python 3.12+, FastAPI, SQLAlchemy, Alembic, standard SQLite / PostgreSQL database.
- **Frontend / Mobile**: Flutter 3.10+, targeting iOS & Android.

## Setup Instructions

### 1. Backend (FastAPI)
Navigate to the `backend/` directory from the repository root:
```bash
cd backend
```

Create and activate a virtual environment:
```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
# Mac/Linux
source .venv/bin/activate
```

Install dependencies:
```bash
pip install -r requirements-dev.txt
```

Set up your environment variables by copying the example file:
```bash
cp .env.example .env
```
_Edit `.env` to provide a valid `DATABASE_URL` and your `GEMINI_API_KEY`._

Run database migrations:
```bash
alembic upgrade head
```

Run the server:
```bash
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### 2. Mobile (Flutter)
Navigate to the `mobile/` directory:
```bash
cd mobile
```

Install packages:
```bash
flutter pub get
```

Run the app on your emulator or connected device:
```bash
flutter run
```

## Running Tests
Tests are located in `backend/tests/` and can be run using pytest (installed via `requirements-dev.txt`):
```bash
cd backend
pytest
```
