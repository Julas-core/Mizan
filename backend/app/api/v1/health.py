from fastapi import APIRouter
from app.core.config import settings
from app.services.llm_service import GEMINI_MODEL

router = APIRouter()

@router.get("/health", response_model=dict)
def health_check():
    """
    Minimal health check endpoint to verify the API is running.
    """
    return {
        "status": "ok",
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
