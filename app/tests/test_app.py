"""Tests automatisés (pytest).

Ces tests s'exécutent SANS infrastructure : on force DATABASE_URL sur une base
SQLite locale avant d'importer l'application. Ils peuvent donc tourner en local
et dans la CI (GitHub Actions) sans avoir besoin d'un PostgreSQL.
"""
import os

# IMPORTANT : définir la base AVANT d'importer l'app (db.py lit l'env à l'import).
os.environ["DATABASE_URL"] = "sqlite:///./test_tickets.db"

from app.db import Base, engine  # noqa: E402
from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

# Crée les tables sur la base de test.
Base.metadata.create_all(bind=engine)

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "healthy"


def test_root():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_create_and_list_ticket():
    r = client.post(
        "/tickets",
        json={"title": "Imprimante HS", "description": "RDC bâtiment A", "priority": "high"},
    )
    assert r.status_code == 201
    created = r.json()
    assert created["id"] > 0
    assert created["status"] == "open"

    r2 = client.get("/tickets")
    assert r2.status_code == 200
    assert any(t["title"] == "Imprimante HS" for t in r2.json())


def test_get_unknown_ticket_returns_404():
    r = client.get("/tickets/999999")
    assert r.status_code == 404


def test_metrics_exposed():
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"starlette_requests_total" in r.content
