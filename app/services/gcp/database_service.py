import logfire
from sqlalchemy import create_engine, Column, String, Text, DateTime, JSON, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from google.cloud.sql.connector import Connector, IPTypes
from app.config import settings


Base = declarative_base()


class QueryLog(Base):
    __tablename__ = 'query_logs'
    id = Column(String, primary_key=True)
    query = Column(Text)
    response = Column(Text)
    latency = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)
    metadata_info = Column(JSON)
    
# Initialize Cloud SQL Connector
connector = Connector()


def getconn():
    conn = connector.connect(
        settings.DB_CONNECTION_NAME,
        "pg8000",
        user=settings.DB_USER,
        password=settings.DB_PASS,
        db=settings.DB_NAME,
        ip_type=IPTypes.PUBLIC  # Or PRIVATE if using VPC
    )
    return conn

# Database Engine
try:
    if settings.DB_CONNECTION_NAME:
        engine = create_engine("postgresql+pg8000://", creator=getconn)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        # Create tables
        Base.metadata.create_all(bind=engine)
        logfire.info("✅ Cloud SQL (Postgres) Connected")
    else:
        logfire.warning("⚠️ DB_CONNECTION_NAME not set. Audit logging disabled.")
        SessionLocal = None
except Exception as e:
    logfire.error(f"❌ Database Init Failed: {e}")
    SessionLocal = None
    


def log_query_to_db(query_id: str, query: str, response: str, latency: float, metadata: dict = None):
    if not SessionLocal: return
    try:
        db = SessionLocal()
        log_entry = QueryLog(
            id=query_id,
            query=query,
            response=response,
            latency=latency,
            metadata_info=metadata
        )
        db.add(log_entry)
        db.commit()
        db.close()
    except Exception as e:
        logfire.error(f"❌ DB Logging Failed: {e}")
