#!/usr/bin/env bash
# Sauvegarde horodatée de la base PostgreSQL (dump SQL compressé).
# Usage : bash scripts/backup.sh
set -euo pipefail

PG_CONTAINER="${PG_CONTAINER:-deploy-postgres-1}"
DB_USER="${DB_USER:-ticket}"
DB_NAME="${DB_NAME:-ticketing}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"

mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
FILE="$BACKUP_DIR/${DB_NAME}_${TS}.sql.gz"

echo "Sauvegarde de la base '$DB_NAME' (conteneur '$PG_CONTAINER')..."
# --clean --if-exists : le dump pourra être rejoué proprement (restauration idempotente)
docker exec "$PG_CONTAINER" pg_dump -U "$DB_USER" --clean --if-exists "$DB_NAME" | gzip > "$FILE"

echo "Sauvegarde créée : $FILE"
ls -lh "$BACKUP_DIR"
