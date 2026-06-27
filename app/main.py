"""CloudOps Ticketing — API de gestion de tickets / incidents.

Endpoints :
 - GET  /            : page d'accueil (statut + lien docs)
 - GET  /health      : sonde de vivacité (Docker healthcheck + blackbox-exporter)
 - GET  /tickets     : liste des tickets
 - POST /tickets     : création d'un ticket
 - GET  /tickets/{id}: détail d'un ticket
 - GET  /metrics     : métriques Prometheus (latence, nb requêtes, statut HTTP)
"""
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session
from starlette_exporter import PrometheusMiddleware, handle_metrics

from app.db import Base, Ticket, engine, get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Création des tables au démarrage (idempotent — ne casse rien si elles existent).
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="CloudOps Ticketing", version="1.0.0", lifespan=lifespan)

# Middleware métriques Prometheus.
# group_paths=True : /tickets/123 et /tickets/456 sont agrégés sous /tickets/{id}
# → évite l'explosion de cardinalité (un label par URL = bombe mémoire).
app.add_middleware(PrometheusMiddleware, app_name="cloudops_ticketing", group_paths=True)
app.add_route("/metrics", handle_metrics)


# ---- Schémas d'entrée/sortie (Pydantic) ----
class TicketIn(BaseModel):
    title: str
    description: str = ""
    priority: str = "medium"


class TicketOut(TicketIn):
    id: int
    status: str

    model_config = {"from_attributes": True}


# ---- Routes ----
@app.get("/")
def root():
    return {"app": "CloudOps Ticketing", "status": "ok", "docs": "/docs"}


@app.get("/health")
def health():
    """Sonde de santé : utilisée par le healthcheck Docker et le blackbox-exporter."""
    return {"status": "healthy"}


@app.get("/tickets", response_model=list[TicketOut])
def list_tickets(db: Session = Depends(get_db)):
    return db.scalars(select(Ticket)).all()


@app.post("/tickets", response_model=TicketOut, status_code=201)
def create_ticket(payload: TicketIn, db: Session = Depends(get_db)):
    ticket = Ticket(
        title=payload.title,
        description=payload.description,
        priority=payload.priority,
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket


@app.get("/tickets/{ticket_id}", response_model=TicketOut)
def get_ticket(ticket_id: int, db: Session = Depends(get_db)):
    ticket = db.get(Ticket, ticket_id)
    if ticket is None:
        raise HTTPException(status_code=404, detail="Ticket introuvable")
    return ticket
