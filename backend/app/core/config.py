from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Mizan Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    ENVIRONMENT: str = "development"

    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:8000,http://localhost:3000"

    # Database
    DATABASE_URL: str

    # Authentication
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Gemini LLM
    GEMINI_API_KEY: Optional[str] = None

    # Risk Model Weights (must sum to > 0, auto-normalized)
    RISK_W_AFFORD: float = 0.5
    RISK_W_BEHAVE: float = 0.3
    RISK_W_GOAL: float = 0.2
    MAX_BEHAVIOR_PENALTY: float = 0.25
    MIN_GOAL_WINDOW_DAYS: int = 7

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
