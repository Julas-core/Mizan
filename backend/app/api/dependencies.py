from typing import Generator
from app.db.session import SessionLocal

def get_db() -> Generator:
    """
    Dependency function to get DB sessions per FastAPI request.
    It guarantees the session is closed after the request completes.
    """
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()
