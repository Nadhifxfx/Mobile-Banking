"""
Database configuration and session management
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Database URL configuration
# Format: postgresql://username:password@host:port/database
# Or SQLite: sqlite:///./ebanking.db
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./ebanking.db"  # Default to SQLite for easy testing
)

# Create SQLAlchemy engine
# Check if using SQLite (for testing) or PostgreSQL (for production)
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},  # Needed for SQLite
        echo=False  # Set to True for SQL query logging
    )
else:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
        echo=False  # Set to True for SQL query logging
    )

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()


def get_db():
    """
    Dependency untuk mendapatkan database session
    Digunakan di FastAPI dengan Depends()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    Initialize database - create all tables
    Call this once at application startup
    """
    Base.metadata.create_all(bind=engine)
