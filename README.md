# CloudOps Ticketing

Déploiement **automatisé et supervisé** d'une application web conteneurisée de
gestion de tickets/incidents sur **Azure**, dans le cadre du Titre Professionnel
**Administrateur Système DevOps (RNCP36061)**.

> Architecture volontairement **mono-VM** (une machine, Docker Compose) : simple,
> reproductible, défendable — pensée comme une **V1 évolutive** vers la haute
> disponibilité / Kubernetes.

## Architecture

```
Internet ──> Azure NSG (22←mon IP, 80, 443) ──> VM Ubuntu 24.04 (Standard_B2s)
                                                   │  Docker Compose
   ┌───────────────────────────────────────────────┴───────────────────────────┐
   │ Nginx (reverse proxy) → FastAPI (app) → PostgreSQL (volume persistant)      │
   │ Supervision : Prometheus + Grafana + node-exporter + cAdvisor + blackbox    │
   └────────────────────────────────────────────────────────────────────────────┘
```

## Stack technique

| Domaine | Outils |
|---|---|
| IaC | Terraform (azurerm), cloud-init |
| Conteneurs | Docker, Docker Compose |
| Application | FastAPI (Python), PostgreSQL |
| CI/CD | GitHub Actions, GitHub Container Registry (GHCR) |
| Supervision | Prometheus, Grafana, node-exporter, cAdvisor, blackbox-exporter |
| Sécurité | SSH par clé, NSG, ufw, fail2ban, secrets GitHub |

## Démarrage rapide (local)

```bash
# 1. Tests automatisés (aucune infra requise — SQLite)
pip install -r app/requirements.txt
pytest

# 2. Stack locale complète (nécessite Docker Desktop)
cp .env.example .env          # puis adapter POSTGRES_PASSWORD
docker compose up --build
# Application :  http://localhost:8000        (docs : /docs)
# Santé        :  http://localhost:8000/health
# Métriques    :  http://localhost:8000/metrics
```

## Endpoints de l'application

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/` | accueil / statut |
| GET | `/health` | sonde de vivacité (healthcheck + supervision) |
| GET | `/tickets` | liste des tickets |
| POST | `/tickets` | création d'un ticket |
| GET | `/tickets/{id}` | détail d'un ticket |
| GET | `/metrics` | métriques Prometheus |

## Structure du dépôt

```
app/        Application FastAPI + Dockerfile + tests
infra/      Terraform (infrastructure Azure) + cloud-init        [J3]
deploy/     docker-compose de production + Nginx + supervision   [J3-J5]
scripts/    Sauvegarde / restauration PostgreSQL                 [J6]
.github/    Pipeline CI/CD GitHub Actions                        [J4]
docs/       Captures d'écran + dossier projet
```

## Compétences couvertes (RNCP36061)

Bloc 1 (infra cloud automatisée), Bloc 2 (déploiement continu d'application),
Bloc 3 (supervision) — soit les **11 compétences** du référentiel.
