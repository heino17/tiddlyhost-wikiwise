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

Im lokalen Test ohne eigene Domain `DOMAIN=localhost` in `.env` eintragen –
ansonsten meldet Rails `403 Forbidden`, weil der Hostname nicht zur
konfigurierten Domain passt. Ein Eintrag `127.0.0.1 tiddlyhost.local` in
`/etc/hosts` erledigt dasselbe für den Default-Namen.

Einen Administrator mit Passwort anlegen (ohne E-Mail-Bestätigung, da SMTP
nicht konfiguriert ist):

```bash
./install.sh --admin-email du@example.de --admin-name "Dein Name"
```

Das Passwort wird erzeugt und ausgegeben; mit `--admin-passwort …` kannst du
ein eigenes setzen. Als Benutzername für die Schaufenster-Seite (Hub) nimmt
das Skript den Teil der E-Mail vor dem `@`; mit `--admin-username …` wählst du
einen anderen. Ohne Benutzername gibt es keine Hub-Seite, und die Namen der
Eigentümer auf `/explore` und `/templates` sind dann keine Links.

## Die Datei `.env`

`.env` ist die einzige Datei, die du anfasst. Alles andere wird daraus
erzeugt. Wichtig:

| Variable | Bedeutung |
| --- | --- |
| `DOMAIN` | Domain oder IP, unter der du erreichbar bist |
| `HTTP_PORT` | Port des Webservers (Default `8080`) |
| `TIDDLHOST_IMAGE` | Image inkl. Tag, z. B. `:latest` oder `:v0.1.0` |
| `SECRET_KEY_BASE`, `DB_PASSWORD` | werden automatisch erzeugt – **nicht** ändern, sobald Nutzer existieren |

Nach einer Änderung an `DOMAIN` oder `HTTP_PORT` einfach `./install.sh`
nochmal ausführen: die Datei `config/settings_local.yml` wird daraus neu
erzeugt und die App-Container neu gestartet. Ohne diesen Schritt antwortet
die App mit `403 Forbidden` (Rails „Blocked hosts"), weil sie den alten
Hostnamen noch im Kopf hat.

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
TIDDLHOST_IMAGE=ghcr.io/heino17/tiddlyhost-wikiwise:v0.1.3
```

## Häufige Probleme

**`DB_PASSWORD passt nicht zum vorhandenen Datenbank-Volume.`**

Das Datenbank-Volume `th_deploy_db_data` überlebt `docker compose down`
und auch das Löschen einzelner Container. Postgres merkt sich das Passwort,
mit dem es beim allerersten Start initialisiert wurde – ein später
geändertes `DB_PASSWORD` in `.env` führt zu „password authentication
failed". `install.sh` erkennt das und bricht vor den Migrationen ab.
Zwei Varianten:

1. **Daten behalten:** altes `DB_PASSWORD` in `.env` eintragen
   (steht ggf. in einem Backup oder einer alten `.env`) und
   `./install.sh` erneut ausführen.
2. **Daten verwerfen:** `docker compose down -v` (löscht die Volumes)
   und `./install.sh` neu starten – die Datenbank wird dann frisch
   mit dem aktuellen Passwort initialisiert.

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
