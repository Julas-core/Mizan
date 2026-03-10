from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.config import settings
from app.services.llm_service import GEMINI_MODEL
from app.api import dependencies

router = APIRouter()

@router.get("/health", response_model=dict)
def health_check(db: Session = Depends(dependencies.get_db)):
    """
    Health check endpoint verifying API and Database status.
    """
    db_status = "ok"
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        db_status = "error"

    return {
        "status": "ok",
        "database": db_status,
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION
    }

@router.get("/health/ai", response_model=dict)
def ai_health_check():
    """
    AI integration health endpoint.
    Indicates whether Gemini key is configured and which model is targeted.
    """
    return {
        "status": "ok",
        "gemini_configured": bool(settings.GEMINI_API_KEY),
        "model": GEMINI_MODEL,
    }
