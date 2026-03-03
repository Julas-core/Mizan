from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1 import health, users, onboarding, decisions, purchases
from app.services.scheduler import start_scheduler

def get_application() -> FastAPI:
    application = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        openapi_url=f"{settings.API_V1_STR}/openapi.json"
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @application.on_event("startup")
    async def startup_event():
        start_scheduler()

    application.include_router(
        health.router, 
        prefix=settings.API_V1_STR, 
        tags=["health"]
    )
    application.include_router(
        users.router,
        prefix=f"{settings.API_V1_STR}/users",
        tags=["users"]
    )
    application.include_router(
        onboarding.router,
        prefix=f"{settings.API_V1_STR}/onboarding",
        tags=["onboarding"]
    )
    application.include_router(
        decisions.router,
        prefix=f"{settings.API_V1_STR}/decisions",
        tags=["Decision Analysis"]
    )
    application.include_router(
        purchases.router,
        prefix=f"{settings.API_V1_STR}/purchases",
        tags=["Purchases & Reflections"]
    )

    return application

app = get_application()
