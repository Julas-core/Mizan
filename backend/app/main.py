from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.core.rate_limit import limiter
from app.api.v1 import health, users, onboarding, decisions, purchases

from contextlib import asynccontextmanager
from app.core.logging_config import setup_logging
from app.api.errors import add_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    from app.services.scheduler import start_scheduler, stop_scheduler
    start_scheduler()
    yield
    stop_scheduler()

def get_application() -> FastAPI:
    application = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        openapi_url=f"{settings.API_V1_STR}/openapi.json",
        lifespan=lifespan,
    )

    application.state.limiter = limiter
    application.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    add_exception_handlers(application)

    allowed_origins = [o.strip() for o in settings.ALLOWED_ORIGINS.split(",")]
    application.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

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

    # Auth routes (no prefix — mounted at /api/v1/auth)
    from app.api.v1 import auth
    application.include_router(
        auth.router,
        prefix=f"{settings.API_V1_STR}/auth",
        tags=["Authentication"]
    )

    return application

app = get_application()
