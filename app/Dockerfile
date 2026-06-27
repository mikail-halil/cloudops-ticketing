# syntax=docker/dockerfile:1
# ---- Étape 1 : build des dépendances (multi-stage) ----
FROM python:3.12-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
# --prefix isole les paquets pour les recopier dans l'image finale (plus légère).
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Étape 2 : image finale minimale ----
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /code

# Récupère uniquement les dépendances compilées de l'étape précédente.
COPY --from=builder /install /usr/local
COPY app/ ./app/

# Utilisateur non-root (bonne pratique sécurité : réduit la surface d'attaque).
RUN useradd --create-home appuser && chown -R appuser /code
USER appuser

EXPOSE 8000

# Sonde de santé intégrée au conteneur (statut visible dans `docker compose ps`).
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
