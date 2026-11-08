# 🇩🇪 Tiddlyhost-wikiwise  
**+ rails I18n Sprach-Implementierung**  
**+ Kommentar- & Bewertung der Wikis/Seiten**  
**+ Shoutbox-Mini-Chat-Widget**  
**+ Erweiterter Admin-Bereich für Einstellungen**  
**+ Admin‑Bereich – Benutzerverwaltung erweitert**  
**+ Cookie-Banner - EU-Cookie-Richtlinien, DSGVO und TTDSG**  
**+ Gäste-Login für jedes Wiki**  
**+ SimpleWiki-Hosting für leichtgewichtige Dateninsel-Wikis**<br>
**+ Live-Verfügbarkeitsprüfung der Wiki-Adresse beim Anlegen**<br>
**+ Einheitliches Wikiwise-Branding (Logo, Favicon, Link-Icon)**

- 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN - Schalter in menu bar

- macht Spaß! :)  
- Sprachen einzeln an- und ausschalten
- weitere Sprachen einfach zu implementieren  
- beachte die Ports!  
 
...ist ein Fork von [Tiddlyhost-com](https://github.com/tiddlyhost/tiddlyhost-com) mit einer 
- in 7 weitere Sprachen übersetzten Oberfläche,
- durch Implementierung von I18n Sprachunterstützung. **Siehe: [Readme_i18n.md](Readme_i18n.md)**
- Erweitert um Kommentar & Bewertung der Tiddlyhost-Wikis. **Siehe: [Readme_Comments_and_voting.md](Readme_Comments_and_voting.md)**  
- Der Admin-Bereich wurde um eine Registrierkarte/Tab erweitert  
  für direkten Zugriff auf einige Funktionen **Siehe: [Readme-Admin-tab.md](Readme-Admin-tab.md)**   
- Die Benutzerverwaltung wurde erweitert **Siehe: [Readme-User-Management.md](Readme-User-Management.md)**  
- Erweitert um ein Shoutbox-Mini-Chat-Widget **Siehe: [Readme_Shoutbox.md](Readme_Shoutbox.md)** 
- Gäste-Login für jedes Wiki **Siehe: [Readme_Collaborator_Login.md](Readme_Collaborator_Login.md)**
- Spezielle Impressum-Seite für den Betrieb in Europa, im Admin-Bereich ein-/ausschaltbar **Siehe: [Readme-Admin-tab.md](Readme-Admin-tab.md)**
- SimpleWiki-Wikis können direkt angelegt und als leichtgewichtige Dateninsel gehostet werden.
- Beim Hochladen einer SimpleWiki-Datei werden Inhalt, Titel und Untertitel vollständig übernommen.
- Beim Anlegen wird die gewünschte Wiki-Adresse live auf Verfügbarkeit geprüft.
- Einheitliches Wikiwise-Branding mit SimpleWiki-Logo, Favicon und Link-Icon in der Seitenliste.
- Speicherverlauf mit gestaffelter Aufbewahrung (Recent-Puffer, Sitzungs- und Tagessicherungen) sowie manuellen Wiederherstellungspunkten. **Siehe: [Readme_History_Retention.md](Readme_History_Retention.md)**

**Docker-Installation für den Endanwender-Betrieb:** **Siehe [deploy/README.md](deploy/README.md)**.

Ich dachte, es könnte das Interesse an der Software steigern, zum Beispiel bei deutschen, spanischen oder französischen Programmierern...  

Lieben Dank an Simon Baird, für den Spaß mit Deiner tollen Software!

( ･_･)»(ﾟｰﾟ)»(｡_｡)(｡_｡)«(ﾟｰﾟ)«( ･_･)
  
## clone branch:  
SSH:  
```
git clone git@github.com:heino17/tiddlyhost-wikiwise.git  
```
https:  
```
git clone https://github.com/heino17/tiddlyhost-wikiwise.git  
```
```
cd tiddlyhost-wikiwise
```

**Nachfolgend die originale Tiddlyhost-Readme ins Deutsche übersetzt (Pfade und Ports an dieses Repo angepasst).**

# Tiddlyhost 

## Über

[Tiddlyhost](https://tiddlyhost.com/) ist das neue Tiddlyspot, ein Hosting-Dienst für TiddlyWiki.

Es soll die einfachste und beste Möglichkeit sein, TiddlyWiki online zu nutzen.  

Im Gegensatz zum ursprünglichen Tiddlyspot bietet Tiddlyhost folgende Funktionen:

* Sicheres SSL
* Passwortwiederherstellung
* TiddlyWiki5-Unterstützung
* Offener Quellcode

Weitere Informationen findest du unter
[FAQ](https://github.com/tiddlyhost/tiddlyhost-com/wiki/FAQ).

### Aktueller Status
--------------

Tiddlyhost wird aktiv weiterentwickelt.

Aktuelle Statusinformationen findest du unter
[Journal](https://github.com/tiddlyhost/tiddlyhost-com/wiki/Journal).

## Erste Schritte (für Entwickler)
--------------------------------

Todo: Eine andere Möglichkeit beschreiben, ein Entwicklungssystem einzurichten, in dem Rails direkt ausgeführt wird.

### Umgebung vorbereiten

Du benötigst Docker und Docker Compose [auf Deinem System installiert](https://docs.docker.com/engine/install/).

Schau dir den Code an:

    git clone git@github.com:heino17/tiddlyhost-wikiwise.git
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

Rufe die Seite <https://tiddlyhost.local:7443/> in Deinem Browser auf, und du solltest eine funktionierende Webanwendung sehen.

Der Dev-Stack veröffentlicht HTTPS auf Port 7443. Aufrufe über `http://tiddlyhost.local:8034/` werden dorthin umgeleitet.

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

### Lizenz

Tiddlyhost ist eine Open-Source-Software. Sie verwendet eine BSD-Lizenz. Siehe
[LICENSE.md](LICENSE.md).

# 🇬🇧 Tiddlyhost-wikiwise  
**+ rails I18n language implementation**  
**+ Comment & Voting for Wikis/Sites**  
**+ Shoutbox-Mini-Chat-Widget**  
**+ Advanced Admin Panel for Settings**  
**+ Admin area – User management expanded**  
**+ Cookie-Banner - EU Cookie Directives, GDPR, and TTDSG**  
**+ Guest login for every wiki**  
**+ SimpleWiki hosting for lightweight data-island wikis**<br>
**+ Live availability check for the wiki address during creation**<br>
**+ Consistent Wikiwise branding (logo, favicon, link icon)**

- 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN - Switch in menu bar

- It's fun! :)  
- Activate and deactivate languages individually  
- more languages easy to implement  
- note the ports!  
 
...is a fork of [Tiddlyhost-com](https://github.com/tiddlyhost/tiddlyhost-com) with a 
- interface translated into 7 additional languages,
- through the implementation of I18n language support. **More about in [Readme_i18n.md](Readme_i18n.md)**
- Expanded with comments and ratings for Tiddlyhost wikis. **More about in [Readme_Comments_and_voting.md](Readme_Comments_and_voting.md)**
- A new tab has been added to the admin area for direct access to various features **See: [Readme-Admin-tab.md](Readme-Admin-tab.md)**  
- User management has been expanded **See: [Readme-User-Management.md](Readme-User-Management.md)**  
- Extended with a shoutbox mini-chat widget **See: [Readme_Shoutbox.md](Readme_Shoutbox.md)**  
- Guest login for each wiki **See: [Readme_Collaborator_Login.md](Readme_Collaborator_Login.md)**  
- Dedicated legal notice (imprint) page for operation in Europe, can be enabled/disabled in the admin area **See: [Readme-Admin-tab.md](Readme-Admin-tab.md)**
- SimpleWiki sites can be created directly and hosted as lightweight data-island wikis.
- Uploading a SimpleWiki file takes over its content, title and subtitle.
- The desired wiki address is checked live for availability during creation.
- Consistent Wikiwise branding with SimpleWiki logo, favicon and link icon in the site list.
- Save history with tiered retention (recent buffer, session and daily snapshots) and manual restore points. **See: [Readme_History_Retention.md](Readme_History_Retention.md)**

**Docker installation for end users:** **See [deploy/README.md](deploy/README.md)**.

I thought it might increase interest in the software, for example among German, Spanish, or French programmers...  
  
Huge thanks to Simon Baird for the fun with your awesome software!

(„• ᴗ •„)
  
## clone branch:  
SSH:  
```
git clone git@github.com:heino17/tiddlyhost-wikiwise.git  
```
https:  
```
git clone https://github.com/heino17/tiddlyhost-wikiwise.git  
```
```
cd tiddlyhost-wikiwise
```

**Below is the original Tiddlyhost readme translated into English (paths and ports adapted to this repository).**

# Tiddlyhost 

## About

[Tiddlyhost](https://tiddlyhost.com/) is the new Tiddlyspot, a hosting service for TiddlyWiki.

It aims to be the easiest and best way to use TiddlyWiki online.  

Unlike the original Tiddlyspot, Tiddlyhost offers the following features:

* Secure SSL
* Password recovery
* TiddlyWiki5 support
* Open source

For more information, see the
[FAQ](https://github.com/tiddlyhost/tiddlyhost-com/wiki/FAQ).

### Current status
--------------

Tiddlyhost is under active development.

For current status information, see the
[Journal](https://github.com/tiddlyhost/tiddlyhost-com/wiki/Journal).

## Getting started (for developers)
--------------------------------

Todo: Describe another way to set up a development environment that runs Rails directly.

### Prepare the environment

You need Docker and Docker Compose [installed on your system](https://docs.docker.com/engine/install/).

Take a look at the code:

    git clone git@github.com:heino17/tiddlyhost-wikiwise.git
    cd tiddlyhost-wikiwise

### Create the container and set up Rails.

Create a container image for development:  

    make build-base

Install all Ruby gems and Node modules and initialize the databases:  

    make rails-init

Run the test suite. Hopefully everything passes:  

    make test

Tiddlyhost uses wildcard subdomains. To simulate this for local development,  
add some entries to your /etc/hosts:

    127.0.0.1 tiddlyhost.local
    127.0.0.1 aaa.tiddlyhost.local
    127.0.0.1 bbb.tiddlyhost.local
    127.0.0.1 foo.tiddlyhost.local
    127.0.0.1 bar.tiddlyhost.local

You should now be able to start Rails as follows:

(It runs in the foreground, so I recommend doing this in a second terminal window.)

    make start

Open <https://tiddlyhost.local:7443/> in your browser, and you should see a working web application.

The dev stack publishes HTTPS on port 7443. Requests to `http://tiddlyhost.local:8034/` are redirected there.

Note that the development environment uses a self-signed SSL certificate.  
You will therefore need to accept the warnings about insecure connections.

### Create an account and create a site

Click “Sign in” and enter some details. An invalid email address is fine.

When running locally, no emails are sent, but you can find the confirmation link for the email by running:

    make signup-link

Click on that link, then you should be able to sign in.

Note: For the first user-created account, the confirmation step is skipped and you are signed in immediately.  
Click “Create” to create a site. Note that you must use a site name  
that matches something you added to your /etc/hosts file, e.g. aaa or bbb.  

When you are done, click “Save” to save the site.  
Click on the site to open it. Accept the certificate warnings again.  
Click the “Save” button and make sure your site could be saved.  

Create more sites or local accounts as needed.

### Other useful commands

Note that the container mounts the `rails` directory, so the code can be edited outside the container while Rails runs inside the container.

You can log into the running container from another terminal as follows:

    make join

From there you can access the Rails console, run tests, etc., inside the container.

You can press Ctrl-C in the terminal where you ran `make start` to stop it.

You can also shut down and clean up like this:

    make cleanup

Note that the Make tasks are mostly just wrappers around `docker compose`, so you can also use your own `docker compose` commands directly if you prefer. Details can be found in the Makefile.

Run `make` on its own to display a complete list of Make commands. Read the Makefile to learn more about what they do.

### License

Tiddlyhost is open-source software. It uses a BSD license. See
[LICENSE.md](LICENSE.md).
