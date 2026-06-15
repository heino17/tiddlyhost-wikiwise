# 🇩🇪 Deutsch und Amerikanisch 🇺🇸  
German and American  

### 🇩🇪 Collaborator-Login für Tiddlyhost-Wikis  

- **Collaborator-Login (Gast-Schreibzugriff für Wikis)**  
  - Mehrere Kollaborateure/Gäste pro Wiki möglich  
  - Jeder Kollaborateur hat einen eigenen Namen und ein eigenes Passwort  
  - Aktivierungs-Schalter pro Kollaborateur (an/aus)  
  - Kollaborateure werden direkt in der Wiki-Edit-Seite verwaltet  
  - Kein eigenes Konto nötig für Gäste  
  - Kein zusätzlicher Tiddler oder Plugin im Wiki nötig  
  - Funktioniert mit jedem bestehenden Wiki sofort  
- **!!! Das Bearbeiten eines Wikis durch 2 Anwender gleichzeitig ist per Tiddlyhost-design vorerst nicht möglich !!!**
  - Aber es ist eine hervorragende Möglichkeit,  helfende Unterstützung einzuladen, ohne das gesamte Konto freizugeben

- **Einladungslink**
  - Einladungslink pro Wiki, direkt in der Edit-Seite sichtbar
  - Klick zum Markieren, dann kopieren – fertig
  - Link + Name + Passwort per beliebigem Kanal weitergeben (Mail, Signal, etc.)

- **Login-Seite für Gäste**
  - Aufruf via `https://wiki-name.tiddlyhost.local/?collaborate`
  - Responsives Design, funktioniert auf Desktop und Mobilgeräten
  - Hell- und Dunkel-Modus werden automatisch übernommen
  - Eingabe von Name und Passwort
  - Fehlermeldung bei falschen Zugangsdaten
  - Session läuft nach 24 Stunden automatisch ab

- **Gast-Session im Wiki**
  - Oranger Banner oben im Wiki: „Eingeloggt als Gast: [Name]"
  - Logout-Button im Banner
  - `$:/status/UserName` wird automatisch auf den Gast-Namen gesetzt
  - Auch der Wiki-Eigentümer bekommt seinen `username` automatisch gesetzt
  - Nur das freigegebene Wiki ist speicherbar – andere Wikis bleiben geschützt

- **Benachrichtigung für den Wiki-Eigentümer**
  - Banner in der Sites-Übersicht: „[Wiki-Name] wurde von Gast [Name] gespeichert, am [Datum]"
  - Lokale Zeitanzeige im Browser des Betrachters (automatisch, ohne Zeitzoneneinstellung)
  - Banner per Klick dauerhaft ausblenden

- **i18n**
  - Alle Texte vollständig übersetzt in alle 8 Sprachen
  - 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN

- **Offene / zukünftige Themen**
  ...


---


### 🇺🇸 Collaborator Login for Tiddlyhost Wikis

- **Collaborator Login (guest write access for wikis)**
  - Multiple collaborators/guests per wiki supported
  - Each collaborator has their own name and password
  - Enable/disable switch per collaborator
  - Collaborators are managed directly in the wiki edit page
  - No account needed for guests
  - No additional tiddler or plugin required in the wiki
  - Works with any existing wiki immediately
- **!!! Due to the way Tiddlyhost is designed, it is currently not possible for two users to edit a wiki at the same time !!!**
  - But it's a great way to invite people to help out without sharing your entire account  

- **Invitation link**
  - One invitation link per wiki, visible directly on the edit page
  - Click to highlight, then copy – done
  - Share link + name + password via any channel (email, Signal, etc.)

- **Login page for guests**
  - Access via `https://wiki-name.tiddlyhost.local/?collaborate`
  - Responsive design, works on desktop and mobile devices
  - Light and dark mode are applied automatically
  - Enter name and password
  - Error message for incorrect credentials
  - Session expires automatically after 24 hours

- **Guest session in the wiki**
  - Orange banner at the top of the wiki: "Logged in as guest: [Name]"
  - Logout button in the banner
  - `$:/status/UserName` is automatically set to the guest's name
  - The wiki owner also gets their `username` set automatically
  - Only the shared wiki is writable – other wikis remain protected

- **Notification for the wiki owner**
  - Banner in the sites overview: "[Wiki name] was saved by guest [Name], on [date]"
  - Local time display in the viewer's browser (automatic, no timezone setting needed)
  - Banner can be permanently dismissed with one click

- **i18n**
  - All texts fully translated into all 8 languages
  - 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN

- **Open / future topics**
  ...
