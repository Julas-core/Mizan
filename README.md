# Mizan — Financial Decision App

Mizan is a financial decision-making tool featuring a cashflow simulation engine and Gemini LLM integration to predict the impact of purchases on user liquidity, savings goals, and overall financial health.

## Tech Stack
- **Backend**: Python 3.11, FastAPI, SQLAlchemy, Alembic, PostgreSQL
- **Mobile**: Flutter 3.29+, Riverpod, GoRouter — targeting iOS & Android
- **Infrastructure**: Docker, Docker Compose, GitHub Actions CI/CD

---

## Quick Start (Docker)

The fastest way to run the full stack:

```bash
# 1. Copy and configure your environment
cp backend/.env.example backend/.env
# Edit backend/.env → set SECRET_KEY and GEMINI_API_KEY

# 2. Launch everything
docker compose up --build
```

The API will be available at `http://localhost:8000`. Migrations run automatically on startup.

---

## Local Development Setup

### 1. Backend (FastAPI)

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate
# Mac/Linux
source .venv/bin/activate

pip install -r requirements.txt
pip install -r requirements-dev.txt

cp .env.example .env
# Edit .env → set DATABASE_URL, SECRET_KEY, GEMINI_API_KEY

alembic upgrade head
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### 2. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

To target a local backend from an Android emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

---

## Running Tests

### Backend
```bash
cd backend
pytest tests/ -v
```

### Mobile
```bash
cd mobile
flutter test
```

---

## CI/CD

The project uses **GitHub Actions** (`.github/workflows/main.yml`) to run on every push to `main` or `develop`:

| Job | What it does |
|-----|-------------|
| `backend` | Lint (flake8) → Alembic migrations → pytest against PostgreSQL |
| `mobile` | `flutter analyze` → `flutter test` |
| `docker` | Build the Docker image as a smoke test |

---

## API Versioning Strategy

All backend endpoints are prefixed with `/api/v1/`. When breaking changes are introduced:

1. **Create a new version prefix** (`/api/v2/`) with its own router module.
2. **Keep `/api/v1/` running** in parallel for a deprecation period (minimum 2 release cycles).
3. **Add a `Sunset` header** to deprecated endpoints indicating the removal date.
4. **Document changes** in a `CHANGELOG.md` entry before each release.

This ensures mobile clients on older app versions continue working until users update.

---

## Project Structure

```
Mizan/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # Route handlers
│   │   ├── core/            # Config, security, rate limiting
│   │   ├── models/          # SQLAlchemy ORM models
│   │   ├── schemas/         # Pydantic request/response schemas
│   │   ├── services/        # Business logic, LLM, scheduler
│   │   └── db/              # Database session & base class
│   ├── alembic/             # Database migrations
│   ├── tests/               # Pytest suite
│   ├── Dockerfile
│   └── requirements.txt
├── mobile/
│   └── lib/
│       ├── core/            # API client, errors, theme
│       ├── models/          # Typed Dart models
│       ├── providers/       # Riverpod state management
│       ├── repositories/    # Data access layer
│       ├── screens/         # UI screens
│       └── widgets/         # Reusable components
├── docker-compose.yml
└── .github/workflows/       # CI/CD pipelines
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SECRET_KEY` | ✅ | JWT signing key (`openssl rand -hex 32`) |
| `GEMINI_API_KEY` | ⚠️ | Required for AI insights |
| `ALLOWED_ORIGINS` | ❌ | CORS origins (comma-separated) |
| `ENVIRONMENT` | ❌ | `development` / `staging` / `production` |
