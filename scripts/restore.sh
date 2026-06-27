#!/usr/bin/env bash
# Restauration de la base PostgreSQL depuis un dump .sql.gz
# Usage : bash scripts/restore.sh <chemin/vers/dump.sql.gz>
set -euo pipefail

PG_CONTAINER="${PG_CONTAINER:-deploy-postgres-1}"
DB_USER="${DB_USER:-ticket}"
DB_NAME="${DB_NAME:-ticketing}"
FILE="${1:?Usage: bash scripts/restore.sh <fichier.sql.gz>}"

echo "Restauration de la base '$DB_NAME' depuis '$FILE'..."
gunzip -c "$FILE" | docker exec -i "$PG_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME"
echo "Restauration terminée."
