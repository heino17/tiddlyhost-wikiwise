# Tiddlyhost-Wikiwise installieren

Diese Installation startet Tiddlyhost-Wikiwise mit Docker – ohne Quellcode,
ohne Ruby/Node/Postgres von Hand.

**Voraussetzung:** Docker mit Compose v2 (`docker compose version`).

## Schnellstart

```bash
cp .env.example .env      # Domain/Port eintragen
./install.sh              # Container starten + Datenbank vorbereiten
```

Danach: <http://localhost:8080> (bzw. `http://DEINE-DOMAIN:PORT`).

Einen Administrator mit Passwort anlegen (ohne E-Mail-Bestätigung, da SMTP
nicht konfiguriert ist):

```bash
./install.sh --admin-email du@example.de --admin-name "Dein Name"
```

Das Passwort wird erzeugt und ausgegeben; mit `--admin-passwort …` kannst du
ein eigenes setzen.

## Die Datei `.env`

`.env` ist die einzige Datei, die du anfasst. Alles andere wird daraus
erzeugt. Wichtig:

| Variable | Bedeutung |
| --- | --- |
| `DOMAIN` | Domain oder IP, unter der du erreichbar bist |
| `HTTP_PORT` | Port des Webservers (Default `8080`) |
| `TIDDLHOST_IMAGE` | Image inkl. Tag, z. B. `:latest` oder `:v0.1.0` |
| `SECRET_KEY_BASE`, `DB_PASSWORD` | werden automatisch erzeugt – **nicht** ändern, sobald Nutzer existieren |

## Bedienung

```bash
docker compose up -d        # starten
docker compose down         # stoppen (Daten bleiben erhalten)
docker compose logs -f app  # Logs
docker compose exec db pg_dump -U postgres tiddlyhost > backup.sql
```

Daten liegen in den Volumes `th_deploy_db_data` (Datenbank) und
`th_deploy_app_log`.

## Aktualisieren

```bash
docker compose pull
docker compose up -d
```

Das Image liegt öffentlich im GitHub Container Registry unter
`ghcr.io/heino17/tiddlyhost-wikiwise`. Wer keine Überraschungen will,
schreibt in `.env` eine feste Version fest:

```bash
TIDDLHOST_IMAGE=ghcr.io/heino17/tiddlyhost-wikiwise:v0.1.0
```

## Version veröffentlichen (Maintainer)

Ein Push eines Tags `v*` startet den `Release`-Workflow: Testlauf, dann
Build des Produktions-Images und Push nach GHCR als `<tag>` **und**
`latest`.

```bash
git tag v0.1.0
git push origin v0.1.0
```

Voraussetzung: das Package muss auf **public** stehen (GitHub →
Packages → Package settings), sonst können Anwender nicht pullen.

## Aktueller Stand / Einschränkungen

- **Nur HTTP.** TLS/Let's Encrypt ist noch nicht integriert. Für öffentlichen
  Betrieb vorerst einen eigenen Reverse-Proxy davorstellen, der HTTPS
  terminiert (z. B. Caddy, Traefik oder nginx mit Zertifikaten).
- **Kein SMTP.** Ohne Mailserver funktioniert die Anmeldung neuer Nutzer
  nicht (Devise `:confirmable`). Nutzer lässt du deshalb entweder über
  `--admin-email` anlegen oder du bestätigst sie manuell in der Datenbank.
- **Kein automatisches Backup.** Bitte regelmäßig `pg_dump` laufen lassen.
- Subdomains (`meinwiki.tiddlyhost.local`) setzen voraus, dass DNS dorthin
  zeigt; im lokalen Test genügt `127.0.0.1` in `/etc/hosts`.

## TLS (geplant)

Der productive Stack des Repos (`docker-compose-prod.yml`) unterstützt TLS
bereits über `nginx`-Templates aus `ansible/playbooks/templates/docker/` und
Let's Encrypt. Diese Variante hier bewusst noch ohne, damit die Installation
auch ohne freie Ports 80/443 und ohne DNS-Provider-Zugang funktioniert.
