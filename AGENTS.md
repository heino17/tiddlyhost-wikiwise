# AGENTS.md

## Allgemein
- Dieses Repo ist ein Fork von Tiddlyhost (wikiwise-Variante). Wir sind **nicht mehr upstream-kompatibel**.
- CLAUDE.md ist historisch (Original von Simon). Für diese Zusammenarbeit gilt primär diese AGENTS.md.
- Kein Druck, kein festes Ziel. App läuft, wir tasten uns langsam ran.

## Workflow (Push/Branches)
- Vorgehen laut Makefile-Bereich („Strategie A", ab Zeile ~797): `wikiwise-local-translation` = Arbeitsbranch, `main` = stabile/öffentliche Version.
- Bisheriger Flow (zur Orientierung): erst auf `wikiwise-local-translation` arbeiten und pushen (`make git-push-work`), dann Rollout über `make promote-to-public` Richtung `main`.
- **Niemals** ohne expliziten Wunsch pushen/committen.

## AGENTS-Dateien
- `AGENTS.md` = gemeinsame Regeln (darf committet werden).
- `AGENTS_heino17.md` = persönliche Notizen. Wird über `.gitignore` ausgeschlossen (nie commit/push).

## Entwicklung
- Vor Änderungen erst verstehen, was im Repo ist (README, Fork-MDs, Makefile, docker-compose.yml).
- Kleine, sichere Schritte. Erst Theorie klären, dann erst Code.

## Releases / Installation
- Tarball-Release (wie MultiWikiServer) grundsätzlich denkbar, aber Tiddlyhost ist Rails + Docker-Stack.
- Für einfache Installation eher OCI-Image + docker-compose pragmatischer als reiner Tarball.
