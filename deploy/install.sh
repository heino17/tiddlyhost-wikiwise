#!/usr/bin/env bash
#
# Tiddlyhost-Wikiwise – Endanwender-Installation (HTTP).
#
#   cp .env.example .env   # Domain/Port eintragen (nur beim ersten Mal)
#   ./install.sh
#
# Idempotent: ein erneuter Aufruf aktualisiert nur fehlende Teile.
#
set -euo pipefail
cd "$(dirname "$0")"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
CONFIG_DIR="config"
SETTINGS_FILE="$CONFIG_DIR/settings_local.yml"

info() { printf '  \033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32mOK\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '  \033[1;31mFEHLER:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Aufruf: ./install.sh [Optionen]

  --admin-email ADRESSE    Legt nach dem Start einen Superuser an.
  --admin-name NAME        Anzeigename des Superusers (Default: Admin).
  --admin-passwort PASS    Passwort des Superusers (sonst wird eines erzeugt).
  --keep-config            Bestehende config/settings_local.yml nicht überschreiben.
  -h, --help               Diese Hilfe.
EOF
}

KEEP_CONFIG=0
ADMIN_EMAIL=""
ADMIN_NAME="Admin"
ADMIN_PASSWORD=""

while [ $# -gt 0 ]; do
  case "$1" in
    --admin-email)      ADMIN_EMAIL="${2:?}"; shift 2 ;;
    --admin-name)       ADMIN_NAME="${2:?}"; shift 2 ;;
    --admin-passwort|--admin-password) ADMIN_PASSWORD="${2:?}"; shift 2 ;;
    --keep-config)      KEEP_CONFIG=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  usage >&2; die "Unbekannte Option: $1" ;;
  esac
done

#-------------------------------------------------------------
# 1. Voraussetzungen
#-------------------------------------------------------------
info "Prüfe Voraussetzungen"

command -v docker >/dev/null 2>&1 \
  || die "Docker nicht gefunden. Installationsanleitung: https://docs.docker.com/engine/install/"

docker info >/dev/null 2>&1 \
  || die "Der Docker-Dienst läuft nicht oder du hast keine Berechtigung (Gruppe 'docker'?).

    sudo usermod -aG docker \$USER   # danach neu einloggen"

docker compose version >/dev/null 2>&1 \
  || die "'docker compose' (v2) nicht gefunden. Ältere 'docker-compose'-Varianten werden nicht unterstützt."

ok "Docker + Compose vorhanden"

#-------------------------------------------------------------
# 2. .env anlegen bzw. vervollständigen
#-------------------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
  info "Lege $ENV_FILE aus $ENV_EXAMPLE an"
  [ -f "$ENV_EXAMPLE" ] || die "$ENV_EXAMPLE fehlt"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

# Secrets ergänzen (idempotent). Der Aufruf von .env überschreibt
# Umgebungsvariablen bewusst nicht, wir lesen nur die Datei.
ensure_secret() {
  local key="$1" gen="$2"
  if ! grep -q "^${key}=" "$ENV_FILE"; then
    info "Erzeuge $key"
    printf '%s=%s\n' "$key" "$gen" >> "$ENV_FILE"
  fi
}

ensure_secret SECRET_KEY_BASE "$(openssl rand -hex 64 2>/dev/null || head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n')"
ensure_secret DB_PASSWORD     "$(openssl rand -hex 24 2>/dev/null || head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"

set -a
# shellcheck disable=SC1090
. "./$ENV_FILE"
set +a

: "${DOMAIN:?DOMAIN fehlt in $ENV_FILE}"
: "${HTTP_PORT:?HTTP_PORT fehlt in $ENV_FILE}"
: "${SECRET_KEY_BASE:?SECRET_KEY_BASE fehlt in $ENV_FILE}"
: "${DB_PASSWORD:?DB_PASSWORD fehlt in $ENV_FILE}"

TIDDLHOST_IMAGE="${TIDDLHOST_IMAGE:-ghcr.io/heino17/tiddlyhost-wikiwise:latest}"

ok "$ENV_FILE vollständig (Domain: $DOMAIN, Port: $HTTP_PORT)"

#-------------------------------------------------------------
# 3. settings_local.yml erzeugen
#
#    Im Container defaultet settings.yml auf https/ohne Port (nginx+TLS).
#    Ohne TLS müssen wir das korrigieren, sonst verweisen E-Mails und
#    Links auf eine nicht erreichbare Adresse.
#-------------------------------------------------------------
SETTINGS_CHANGED=0
if [ "$KEEP_CONFIG" -eq 1 ] && [ -f "$SETTINGS_FILE" ]; then
  info "Behalte bestehende $SETTINGS_FILE"
else
  info "Erzeuge $SETTINGS_FILE"
  mkdir -p "$CONFIG_DIR"

  if [ "$HTTP_PORT" = "80" ]; then
    PORT_LINE=""
  else
    PORT_LINE="  :port: ${HTTP_PORT}"
  fi

  TMP_SETTINGS="$SETTINGS_FILE.tmp"
  cat > "$TMP_SETTINGS" <<EOF
# Erzeugt von deploy/install.sh – bitte in .env ändern, nicht hier.
url_defaults:
  :host: ${DOMAIN}
  :protocol: http
${PORT_LINE}

# Ohne S3/Wasabi-Zugang (die upstream hinterlegt sind) greifen die
# lokalen Disk-Services. Volumes sind in docker-compose.yml gemountet.
thumbs_storage_service: local1
public_thumbs_storage_service: local2
EOF
  [ -n "$PORT_LINE" ] || sed -i '/^$/d' "$TMP_SETTINGS"

  if [ -f "$SETTINGS_FILE" ] && cmp -s "$TMP_SETTINGS" "$SETTINGS_FILE"; then
    rm -f "$TMP_SETTINGS"
  else
    mv "$TMP_SETTINGS" "$SETTINGS_FILE"
    SETTINGS_CHANGED=1
  fi
fi

# Laufen die Container schon, merken wir uns das: eine geänderte
# settings_local.yml wird erst nach einem Neustart gelesen.
APP_ALREADY_RUNNING=0
if [ -n "$(docker compose ps -q app 2>/dev/null || true)" ]; then
  APP_ALREADY_RUNNING=1
fi

#-------------------------------------------------------------
# 4. Container starten
#-------------------------------------------------------------
info "Starte Container (Image: $TIDDLHOST_IMAGE)"
docker compose up -d

if [ "$SETTINGS_CHANGED" -eq 1 ] && [ "$APP_ALREADY_RUNNING" -eq 1 ]; then
  info "settings_local.yml hat sich geändert – starte app und jobs neu"
  docker compose restart app jobs
fi

# nginx.conf kann sich mit einer neuen Version geändert haben. Ein Reload
# übernimmt die Änderungen; der Resolver in nginx.conf löst "app" danach
# ohnehin laufend neu auf.
if [ -n "$(docker compose ps -q web 2>/dev/null || true)" ]; then
  docker compose exec -T web nginx -s reload >/dev/null 2>&1 || true
fi

#-------------------------------------------------------------
# 4b. Storage-Volumes für die App beschreibbar machen
#
#     Die Named Volumes erben den Besitzer aus dem Image. Bei Bildern, die
#     die Ordner storage1/storage2 nicht enthalten (oder bei Volumes aus
#     einer früheren Installation), gehören sie root und das Anlegen von
#     Thumbnails schlägt mit "EACCES: Permission denied" fehl.
#-------------------------------------------------------------
APP_OWNER="$(docker compose exec -T app id -un 2>/dev/null || echo appuser)"
for dir in /opt/app/storage /opt/app/storage1 /opt/app/storage2; do
  if docker compose exec -T app test -w "$dir" >/dev/null 2>&1; then
    continue
  fi
  warn "$dir ist nicht beschreibbar – setze Besitzer auf $APP_OWNER"
  docker compose exec -T -u root app chown -R "$APP_OWNER:$APP_OWNER" "$dir"
done

#-------------------------------------------------------------
# 5. Datenbank vorbereiten
#-------------------------------------------------------------
info "Warte auf die Datenbank"
for _ in $(seq 1 60); do
  if docker compose exec -T db pg_isready -U postgres -q >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
docker compose exec -T db pg_isready -U postgres >/dev/null 2>&1 \
  || die "Die Datenbank antwortet nicht. 'docker compose logs db' zeigt warum."

# Anmeldung mit den .env-Zugangsdaten testen. Postgres setzt
# POSTGRES_PASSWORD nur beim allerersten Start des Datenverzeichnisses;
# ein später geändertes Passwort in .env führt deshalb zu
# "password authentication failed" – hier früh und verständlich melden.
# Wichtig: per Hostname "db" verbinden, nicht 127.0.0.1 – im Container
# gilt für localhost "trust", übers Netzwerk "scram-sha-256" (wie die App).
if ! docker compose exec -T -e PGPASSWORD="$DB_PASSWORD" db \
    psql -U postgres -h db -d postgres -tAc 'select 1' >/dev/null 2>&1; then
  warn "Die Datenbank akzeptiert das DB_PASSWORD aus .env nicht."
  echo
  echo "  Typische Ursache: Das Datenbank-Volume 'th_deploy_db_data' existiert"
  echo "  schon und wurde mit einem anderen DB_PASSWORD angelegt."
  echo
  echo "  Lösung (zwei Varianten):"
  echo "    1) Daten behalten: altes DB_PASSWORD in .env eintragen"
  echo "       (steht ggf. in einem Backup oder alten .env) und ./install.sh erneut ausführen."
  echo "    2) Daten verwerfen: docker compose down -v && ./install.sh"
  echo
  die "DB_PASSWORD passt nicht zum vorhandenen Datenbank-Volume."
fi

info "Führe Datenbank-Migrationen aus"
docker compose exec -T app bin/rails db:prepare
ok "Datenbank bereit"

#-------------------------------------------------------------
# 6. Optional: Superuser anlegen
#
#    In Production gibt es kein lokales Erst-User-Upgrade
#    (nur development, siehe app/models/user.rb) und Devise
#    verlangt eine E-Mail-Bestätigung, die ohne SMTP nie ankommt.
#    Dieser Pfad legt einen bereits bestätigten Superuser an.
#-------------------------------------------------------------
if [ -n "$ADMIN_EMAIL" ]; then
  ADMIN_PASSWORD="${ADMIN_PASSWORD:-$(openssl rand -hex 12 2>/dev/null || head -c 12 /dev/urandom | od -An -tx1 | tr -d ' \n')}"

  if docker compose exec -T -e ADMIN_EMAIL="$ADMIN_EMAIL" app \
      bin/rails runner 'exit(User.exists?(email: ENV["ADMIN_EMAIL"]) ? 0 : 1)' >/dev/null 2>&1; then
    info "Superuser $ADMIN_EMAIL existiert bereits"
  else
    info "Lege Superuser $ADMIN_EMAIL an"
    docker compose exec -T \
      -e ADMIN_EMAIL="$ADMIN_EMAIL" \
      -e ADMIN_NAME="$ADMIN_NAME" \
      -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
      app bin/rails runner '
        user = User.new(
          email: ENV.fetch("ADMIN_EMAIL"),
          name: ENV.fetch("ADMIN_NAME"),
          password: ENV.fetch("ADMIN_PASSWORD"),
          password_confirmation: ENV.fetch("ADMIN_PASSWORD"),
        )
        user.skip_confirmation!
        user.user_type = UserType.superuser
        user.save!
      '
    ok "Superuser angelegt"
    printf '\n  Login: %s/users/sign_in\n  E-Mail: %s\n  Passwort: %s\n\n' \
      "http://${DOMAIN}:${HTTP_PORT}" "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
  fi
fi

#-------------------------------------------------------------
# 7. Fertig
#-------------------------------------------------------------
printf '\n  \033[1;32mInstallation fertig.\033[0m\n\n'
printf '    Start:      docker compose up -d\n'
printf '    Stoppen:    docker compose down\n'
printf '    Logs:       docker compose logs -f app\n'
printf '    DB-Backup:  docker compose exec db pg_dump -U postgres tiddlyhost > backup.sql\n\n'
printf '    Oberfläche: http://%s:%s\n\n' "$DOMAIN" "$HTTP_PORT"
cat <<EOF
  Hinweise:
    * E-Mail-Versand (SMTP) ist nicht konfiguriert – Anmeldungen ohne
      --admin-email brauchen eine manuelle Bestätigung in der Datenbank.
      Konfiguration: .env ergänzen und docker/Dockerfile.prod bzw. die
      App-Env (SMTP_*) setzen.
    * TLS/HTTPS folgt in einer späteren Version.

EOF
