# AGENTS.md

## Allgemein
- Dieses Repo ist ein Fork von Tiddlyhost (wikiwise-Variante). Wir sind **nicht mehr upstream-kompatibel**.
- CLAUDE.md ist historisch (Original von Simon). Für diese Zusammenarbeit gilt primär diese AGENTS.md.
- Kein Druck, kein festes Ziel. App läuft, wir tasten uns langsam ran.

## Workflow (Push/Branches)
- Vorgehen laut Makefile-Bereich („Strategie A", ab Zeile ~797): `wikiwise-local-translation` = Arbeitsbranch, `main` = stabile/öffentliche Version.
- Aktueller Flow (ab 10/2026, nach Absprache): erst `make git-push-work` (pusht Arbeitsbranch), danach auf ausdrücklichen Wunsch `make git-merge-work-into-public` (zieht `main` auf Arbeitsbranch-Stand). Beide einzeln aufrufen, **nicht** als Kette.
- `make promote-to-public` (Deps-Update + Commit + beides in einem) vorerst **nicht** ungefragt nutzen. `make deps-update-local` ist ein eigenes Thema und wird separat nach Absprache gemacht.
- **Niemals** ohne expliziten Wunsch pushen/committen.
- Commit-Nachrichten auf **Englisch** schreiben (ab 17.10.2026 gewünscht).

## AGENTS-Dateien
- `AGENTS.md` = gemeinsame Regeln (darf committet werden).
- `AGENTS_heino17.md` = persönliche Notizen. Wird über `.gitignore` ausgeschlossen (nie commit/push).

## Entwicklung
- Vor Änderungen erst verstehen, was im Repo ist (README, Fork-MDs, Makefile, docker-compose.yml).
- Kleine, sichere Schritte. Erst Theorie klären, dann erst Code.

## Releases / Installation
- Tarball-Release (wie MultiWikiServer) grundsätzlich denkbar, aber Tiddlyhost ist Rails + Docker-Stack.
- Für einfache Installation eher OCI-Image + docker-compose pragmatischer als reiner Tarball.
