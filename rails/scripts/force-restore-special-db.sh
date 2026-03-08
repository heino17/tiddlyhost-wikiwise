#!/usr/bin/env bash

BACKUP_FILE="../tiddlyhost-local-backups/db/<name of backup file here>"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup nicht gefunden: $BACKUP_FILE"
  exit 1
fi

echo "→ Stoppe alle Services (um Connections freizugeben)..."
docker compose down

echo "→ Kill alle Connections zu app_development..."
docker compose up -d db   # nur DB starten, damit wir psql nutzen können
sleep 2

docker compose exec -T db psql -U postgres -c "
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE datname = 'app_development'
    AND pid <> pg_backend_pid();
"

echo "→ Drop + Recreate DB..."
docker compose exec -T db dropdb -U postgres app_development || true
docker compose exec -T db createdb -U postgres -O postgres app_development

echo "→ Restore läuft..."
zcat "$BACKUP_FILE" | docker compose exec -T db psql -U postgres -d app_development -v ON_ERROR_STOP=1

echo "Fertig. Starte die App wieder mit 'make start'."