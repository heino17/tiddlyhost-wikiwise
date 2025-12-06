Tiddlyhost-wikiwise
===================
Ist eine Kopie von [Tiddlyhost-com](https://github.com/tiddlyhost/tiddlyhost-com) mit einer (fast vollständig :) ) ins Deutsche übersetzten Oberfläche. 
Es ist für meine Server-Umgebung etwas angepasst, siehe [Readme-Anpassungen.md](Readme-Anpassungen.md)

Ich habe für eine online-Präsentation den originalen footer belassen und eine extra Impressum-Seite angelegt.

Lieben Dank an Simon Baird, für den Spaß mit Deiner tollen Software!

( ･_･)»(ﾟｰﾟ)»(｡_｡)(｡_｡)«(ﾟｰﾟ)«( ･_･)

This is a copy of [Tiddlyhost](https://github.com/tiddlyhost/tiddlyhost-com) with an interface that has been (almost completely :) ) translated into German.
It has been slightly adapted for my server environment, see Readme-Anpassungen.md

Huge thanks to Simon Baird for the fun with your awesome software!

(„• ᴗ •„)

Nachfolgend die originale readme ins Deutsche übersetzt, mit angepassten Pfaden zu meiner repo.  
Below is the original readme translated into German, with paths adapted to my repo.

## Tiddlyhost 

### About

[Tiddlyhost](https://tiddlyhost.com/) ist das neue Tiddlyspot, ein Hosting-Dienst für TiddlyWiki.

Es soll die einfachste und beste Möglichkeit sein, TiddlyWiki online zu nutzen.  

Im Gegensatz zum ursprünglichen Tiddlyspot bietet Tiddlyhost folgende Funktionen:

* Sicheres SSL
* Passwortwiederherstellung
* TiddlyWiki5-Unterstützung
* Offener Quellcode

Weitere Informationen findest du unter
[FAQ](https://github.com/tiddlyhost/tiddlyhost-com/wiki/FAQ).

Aktueller Status
--------------

Tiddlyhost wird aktiv weiterentwickelt.

Aktuelle Statusinformationen findest du unter
[Journal](https://github.com/tiddlyhost/tiddlyhost-com/wiki/Journal).

Erste Schritte (für Entwickler)
--------------------------------

Todo: Eine andere Möglichkeit beschreiben, ein Entwicklungssystem einzurichten, in dem Rails direkt ausgeführt wird.

### Umgebung vorbereiten

Du benötigst Docker und Docker Compose [auf Deinem System installiert](https://docs.docker.com/engine/install/).

Schau dir den Code an:

    git clone --branch wikiwise-local-branch https://github.com/heino17/tiddlyhost-wikiwise.git
    cd tiddlyhost-wikiwise

### Erstelle den Container und richte Rails ein.

Erstelle ein Container-Image für die Entwicklung:  

    make build-base

Installiere alle Ruby Gems und Node-Module und initialisiere Sie die Datenbanken:  

    make rails-init

Führe die Testsuite aus. Hoffentlich wird alles bestanden:  

    make test

Tiddlyhost verwendet Wildcard-Subdomains. Um dies für die lokale Entwicklung zu simulieren,  
füge einige Einträge zu Ihrer /etc/hosts hinzu:

    127.0.0.1 tiddlyhost.local
    127.0.0.1 aaa.tiddlyhost.local
    127.0.0.1 bbb.tiddlyhost.local
    127.0.0.1 foo.tiddlyhost.local
    127.0.0.1 bar.tiddlyhost.local

Du solltest nun in der Lage sein, Rails wie folgt zu starten:

(Es läuft im Vordergrund, daher empfehle ich dir, dies in einem zweiten Terminalfenster zu tun.)

    make start

Rufe die Seite <https://tiddlyhost.local/> in Deinem Browser auf, und du solltest eine funktionierende Webanwendung sehen.

Beachte, dass die Entwicklungsumgebung ein selbstsigniertes SSL-Zertifikat verwendet.  
Du musst daher die Warnungen bezüglich unsicherer Verbindungen akzeptieren.

### Erstelle ein Konto und erstelle eine Seite

Klicke auf „Anmelden“ und gib einige Daten ein. Eine falsche E-Mail-Adresse ist in Ordnung.

Bei lokaler Ausführung werden keine E-Mails versendet, aber du kannst den Bestätigungslink für die E-Mail finden, indem du Folgendes ausführst:

    make signup-link

Klicke auf diesen Link, dann solltest du dich anmelden können.

Hinweis: Beim ersten vom Benutzer erstellten Konto wird der Bestätigungsschritt übersprungen und Du wirst sofort angemeldet.  
Klicke auf „Erstellen“, um eine Seite zu erstellen. Beachte, dass du einen Seitennamen verwenden musst,  
der mit etwas übereinstimmt, das du zu deiner /etc/hosts-Datei hinzugefügt hast, z. B. aaa oder bbb.  

Wenn du fertig bist, klicke auf „Speichern“, um die Seite zu speichern.  
Klicke auf die Website, um sie zu öffnen. Akzeptiere erneut die Zertifikatswarnungen. 
Klicke auf die Schaltfläche „Speichern“ und stelle sicher, dass deine Website gespeichert werden konnte.  

Erstelle nach Bedarf weitere Websites oder lokale Konten.

### Weitere nützliche Befehle

Beachte, dass der Container das Verzeichnis „rails“ mountet, sodass der Code dort außerhalb des Containers bearbeitet werden kann, während Rails innerhalb des Containers ausgeführt wird.

Du kannst dich wie folgt in einem anderen Terminal in den laufenden Container einloggen:

    make join

Von dort aus kannst du auf die Rails-Konsole zugreifen, Tests ausführen usw., innerhalb des Containers.

Du kannst Strg-C im Terminal drücken, in dem du „make start“ ausgeführt hast, um es zu beenden.

Du kannst auch so herunterfahren und aufräumen:

    make cleanup

Beachte, dass die Make-Aufgaben meist nur Wrapper für „docker compose“ sind, sodass Du auch direkt Deine eigenen „docker compose“-Befehle verwenden kannst, wenn Du das lieber möchtest. Details findest Du im Makefile.

Führe „make“ allein aus, um eine vollständige Liste der Make-Befehle anzuzeigen. Lies das Makefile, um mehr über deren Funktionen zu erfahren.

Lizenz
-------

Tiddlyhost ist eine Open-Source-Software. Sie verwendet eine BSD-Lizenz. Siehe
[LICENSE.md](LICENSE.md).
