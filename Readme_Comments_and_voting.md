🇩🇪 Deutsch und Amerikanisch 🇺🇸  
German and American

### 🇩🇪 Kommentar- & Voting-System für Tiddlyhost-Wikis

- **Kommentar-Funktion (für Seiten/Wikis)**
  - Einzelner Kommentar pro User pro Site (Unique-Constraint)
  - Formular zum Erstellen / Editieren
  - Anzeige der letzten 2 Kommentare im Tile + „Alle Kommentare“-Link bei mehr als 2 Kommentaren
  - Vollständige Kommentar-Liste auf separater Index-Seite
  - Löschen eigener Kommentare
  - Admin kann jeden Kommentar löschen
  - Aufklappbarer Bereich mit `<details>`-Tag
  - Textfeld mit Buchstaben-Zähler 0/1500, + Fortschrittsbalken grün, gelb, rot
  - i18n-kompatible Texte & Pluralisierung
  - Turbo/Hotwire für live Updates ohne Reload

- **Voting-System (für Seiten/Wikis)**
  - Bewertung mit 1–5 Sternen (Durchschnittsberechnung)
  - Pro User nur eine Bewertung pro Site
  - Aufklappbare Stern-Buttons hinter einem Text-Link („Bewerten“ / „Meine Bewertung: X“)
  - Möglichkeit, eigene Bewertung zu entfernen (erneutes Klicken auf aktuellen Stern)
  - Visuelle Stern-Darstellung mit Helper-Methode
  - Anzeige von Durchschnitt + Anzahl Bewertungen
  - i18n-Texte für Hinweise & Buttons
  - Turbo/Hotwire für live Updates ohne Reload
  
- **Registerkarte 'Kommentare anzeigen' im Admin-Bereich**
  - ⭐ Eine separate Registerkarte/Seite zum Anzeigen aller Kommentare
  - ⭐ Der Administrator kann alle Kommentare einsehen und einzelne Kommentare löschen
  - ⭐ Sofortiges Anzeigen des gesamten Kommentars beim Bewegen des Mauszeigers über die Vorschau der Nachricht
  - ⭐ Link zum Öffnen und Anzeigen des Wikis sowie Link zu allen Kommentaren für dieses spezifische Wiki
  - ⭐ Löschen per Turbo: Der Kommentar wird entfernt, ohne die Seite neu zu laden
  - ⭐ Alarm-Popup-Warnung vorm löschen und Flashmeldung nach erfolgreichem löschen

- **UX- & Design**
  - ⭐ Flash-Meldungen, die nach 3 Sekunden automatisch ausgeblendet werden
  - ⭐ Nach „vote_score“ sortieren (5,0 → 2,7)
  - 💬 Kommentare nach „comments_count“ sortiert
  - 💬 Sortierung nach Kommentaren oder Bewertungen nur, wenn diese Optionen aktiviert sind
  - 🔧 Der Zähler speichert „vote_score“ als Datenbankfeld

- **Offene / zukünftige Themen**
  - ...
  
  
### 🇺🇸 Comment & Voting System for Tiddlyhost Wikis

- **Comment Function (for sites/wikis)**
  - One comment per user per site (unique constraint)
  - Form for creating/editing
  - Display of the last 2 comments in the tile + “All comments” link if there are more than 2 comments
  - Complete comment list on separate index page
  - Delete your own comments
  - Admin can delete any comment
  - Expandable area with `<details>` tag
  - Text field with letter counter 0/1500, + progress bar green, yellow, red
  - i18n-compatible texts & pluralization
  - Turbo/Hotwire for live Updates without reload

- **Voting system (for sites/wikis)**
  - Rating with 1–5 stars (average calculation)
  - Only one rating per user per site
  - Expandable star buttons behind a text link (“Rate” / “My rating: X”)
  - Option to remove your own rating (click on the current star again)
  - Visual star display with helper method
  - Display of average + number of ratings
  - i18n texts for notes & buttons
  - Turbo/Hotwire for live Updates without reload
  
- **'View comments' tab in Admin-area**
  - ⭐ A separate Admin-tab/page for viewing all comments 
  - ⭐ Admin can check out all comments and delete individual ones
  - ⭐ Instant reading of entire comment when hovering over the preview of the message.
  - ⭐ Link to open and view the wiki, and link to all comments for that specific wiki
  - ⭐ Delete via Turbo: Comment is removed without reloading the page
  - ⭐ A pop-up warning before deletion and a flash notification after successful deletion

- **UX & design**
  - ⭐ Flash messages with auto-hide after 3 seconds
  - ⭐ Explore sorted by vote_score (5.0 → 2.7)
  - 💬 Comments sorted by comments_count
  - 💬 Sort by comments or votes only if these options are enabled
  - 🔧 Counter caches + vote_score as a DB field

- **Open/future topics**
  - ...
