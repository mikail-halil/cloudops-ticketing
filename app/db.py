"""Couche d'accès aux données (SQLAlchemy 2.0).

La base est choisie via la variable d'environnement DATABASE_URL :
 - défaut local / tests : SQLite (zéro infrastructure, exécution immédiate)
 - production / docker compose : PostgreSQL (postgresql+psycopg://user:pwd@host:5432/db)

Ce choix illustre le principe "12-factor" : la configuration vient de
l'environnement, jamais du code → la même image tourne en test et en prod.
"""
import os

from sqlalchemy import Integer, String, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

# URL de connexion : SQLite par défaut (local/tests), PostgreSQL injecté en prod.
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tickets.db")

# check_same_thread n'est utile que pour SQLite (mono-fichier).
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

# pool_pre_ping : teste la connexion avant usage (évite les coupures Postgres).
engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    """Classe de base déclarative pour les modèles ORM."""


class Ticket(Base):
    """Un ticket / incident interne."""

    __tablename__ = "tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(String(2000), default="")
    priority: Mapped[str] = mapped_column(String(20), default="medium")  # low | medium | high
    status: Mapped[str] = mapped_column(String(20), default="open")  # open | closed


def get_db():
    """Dépendance FastAPI : ouvre une session et la ferme proprement."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
