🇩🇪 Deutsch und Amerikanisch 🇺🇸  
German and American  
  
### 🇩🇪 
### Admin-Bereich - "Kommentare lesen"-Tab
**Der Admin-Bereich wurde um einen neuen Tab "Kommentare lesen" erweitert.**
- ⭐ Admin kann alle Kommentare anzeigen und einzelne Kommentare löschen
### Admin-Bereich - Einstellungen-Tab
- ⭐ Der Admin-Bereich wurde um einen neuen Tab mit 5 Untertabs erweitert, der direkten Zugriff auf verschiedene Einstellungen bietet:  
  
**Einstellungen-Tab mit Schaltern und Zahleneingaben**  
### Globale Steuerung folgender Features:  
- Tab Allgemein  
  - Startseiten-Einführungsblock _ein-/ausschalten_
  - Spezielle Impressum-Seite _ein-/ausschalten_
  - Cookie-Banner _ein-/ausschalten_
  - Registrierung neuer Benutzer _ein-/ausschalten_
  - Login-Rate-Limit _ein-/ausschalten_
  - Max. Anmeldeversuche pro IP _Zahlenfeld_
  - Max. Fehlversuche pro E-Mail/Benutzername _Zahlenfeld_
  - Zeitfenster in Minuten _Zahlenfeld_
- Tab Gemeinschaft  
  - Kommentarfunktion _ein-/ausschalten_
  - Wiki-Bewertungen _ein-/ausschalten_
  - Shoutbox _ein-/ausschalten_
- Tab Hub & Darstellung  
  - Standard-Theme beim ersten Besuch (Dropdown) _hell/dunkel/auto_
  - Menü-Leiste am oberen Rand fixieren (beim scrollen oben sichtbar) _ein-/ausschalten_
  - Maximale Breite des Frontends _Inputfeld_
  - Anzahl der Wikis pro Seite in der Hub/Explore-Ansicht _Zahlenfeld und +/-_
  - Banner-Nachricht aktivieren, einstellen _Schalter, Dropdown, Textfeld_ 
  - Banner-Nachricht am oberen Rand fixieren (beim scrollen oben sichtbar) _ein-/ausschalten_
- Tab Abonnements  
  - Stripe-Abonnements-Funktion _ein-/ausschalten_
  - Gravatar/Libravatar _ein-/ausschalten_
  - Maximale Anzahl erlaubter Tags pro Seite/Wiki _Zahlenfeld und +/-_
- Tab Speicher & Versionen (Standard-Plan, Premium-Plan nur sichtbar, wenn Abos aktiv)
  - Max. Versionen (Free-Plan) _Zahlenfeld und +/-_
  - Max. Versionen (Standard-Plan) _Zahlenfeld und +/-_
  - Max. Versionen (Premium-Plan) _Zahlenfeld und +/-_
  - Max. Versionen (Tiddlyspot) _Zahlenfeld und +/-_
  - Aufbewahrung: Tage für Tagessicherungen _Zahlenfeld (0 = aus)_
  - Aufbewahrung: Pause zwischen Sitzungen in Minuten _Zahlenfeld (0 = aus)_
  - Aufbewahrung: Anzahl zusätzlicher Sitzungssicherungen _Zahlenfeld (0 = aus)_
  - Details: **[Readme_History_Retention.md](Readme_History_Retention.md)**
  
  - Max. Speichergröße pro Wiki (Free-Plan) _Zahlenfeld und +/-_
  - Max. Speichergröße pro Wiki (Standard-Plan) _Zahlenfeld und +/-_
  - Max. Speichergröße pro Wiki (Premium-Plan) _Zahlenfeld und +/-_
  
  - Max. Speichergröße eines Kontos (Free-Plan) _Zahlenfeld und +/-_
  - Max. Speichergröße eines Kontos (Standard-Plan) _Zahlenfeld und +/-_
  - Max. Speichergröße eines Kontos (Premium-Plan) _Zahlenfeld und +/-_
- Tab Sprachen  
  - Auflistung der aller Sprachen, für systemweites aktivieren/deaktivieren
  - Standardsprache wählen _Dropdown_umschalten_
  - Je Sprache ein Schalter _ein-/ausschalten_
  - Schild für Markierung der Standardsprache
  - Schild für Markierung der aktuell verwendeten Sprache
    - (Standardsprache, aktuelle Sprache, oder alle gleichzeitig deaktivieren wird verhindert! (Flash-Meldungen ))
    - (Es ist möglich, systemweit nur eine einzige Sprache zu verwenden.)
    - (Wenn nur eine systemweite Sprache vorhanden ist, wird in der Kopfzeile kein Sprachauswahlmenü angezeigt.)

- So fügst du eine neue Sprache hinzu: **Siehe: [readme_add_new_language.md](readme_add_new_language.md)**
  
i18n-Unterstützung für alle neuen Admin-Texte und Fehlermeldungen  
Verbesserte Tabellenköpfe in den Admin-Listen (Sites & Users) mit korrekter Mehrsprachigkeit  

Alle geänderten Einstellungen werden sofort und ohne Neustart wirksam.  

### Spezielle Impressum-Seite (für den Betrieb in Europa)
- Die Seite ist unter `/imprint` erreichbar: `rails/app/views/home/imprint.html.haml`.
- Der Footer-Link lässt sich im Admin-Bereich unter **Tab Allgemein → Spezielle Impressum-Seite aktiv** ein- und ausschalten.
- Gelesen wird die Einstellung über `special_imprint_enabled` in `rails/lib/settings/features.rb` (Standard: aktiv).
- Die im Impressum hinterlegten Kontaktdaten sind als Unicode-Zeichen kodiert. Dadurch stehen sie im Quelltext nicht als Klartext, was einfache Datensammler abschreckt. Einen Schutz gegen gezieltes Auslesen bietet das nicht.
- Der Seiteninhalt (Name, Anschrift, E-Mail) ist ein Beispiel und muss vor dem produktiven Einsatz durch die eigenen Angaben ersetzt werden. Als Vorlage diente der [Impressum-Generator von eRecht24](https://www.e-recht24.de/impressum-generator.html).

### Login-Rate-Limit (Admin → Einstellungen → Allgemein)
- Schutz für `POST /users/sign_in` über Rack::Attack, der noch vor Rails greift.
- Zwei getrennte Zähler: **alle Anmeldeversuche pro IP** und **fehlgeschlagene Versuche pro E-Mail/Benutzername**. Erfolgreiche Anmeldungen löschen den Fehlerzähler für diese Identität.
- Standard: **3 Versuche pro IP**, **3 Fehlversuche pro Identität**, Zeitfenster **5 Minuten**. Der 4. Versuch wird mit HTTP 429 und `Retry-After` abgewiesen.
- Alle vier Werte sind im Admin-Bereich einstellbar (Bereiche: 1–100 Attempts, 1–60 Minuten). Ein Abschalten deaktiviert beide Zähler sofort.
- Die Zähler laufen über `Rails.cache`; bei einem `NullStore` (z. B. in Dev/Test ohne Caching) wird automatisch ein `MemoryStore` verwendet.
- Getestet in `rails/test/integration/login_rate_limit_test.rb`.

### Admin-Bereich – Wiki- und Benutzer-Sperre
**Der Admin kann einzelne Wikis oder ganze Benutzerkonten sperren und die Sperre jederzeit aufheben.**
- **Wiki-Sperre** unter `/admin/sites`: Button „Sperren 🚫“ / „Sperre aufheben ✅“ direkt in der Liste, plus Statusfilter.
- **Benutzer-Sperre** unter `/admin/users` und `/admin/users/:id`: Status, Zeitpunkt der Sperrung und Button „User sperren 🚫“ / „Sperre aufheben ✅“. Der angemeldete Admin kann sein **eigenes** Konto nicht sperren.
- **Gesperrtes Wiki**: wird nicht ausgeliefert, Speichern ist blockiert und das Wiki verschwindet aus Hub/Explore.
- **Gesperrter User**: kein Login (auch nicht mit bereits bestehender Session – die Sperre greift beim nächsten Request), keine Passwort-Reset-Mails.
- **Abgeleitete Sperre**: Alle Wikis des gesperrten Users sind ebenfalls nicht verfügbar, ohne dass deren Datensätze umgeschrieben werden. Tspot-Sites haben kein eigenes Sperrflag und folgen ausschließlich der User-Sperre. Einzelne, bereits gesperrte Wikis bleiben nach dem Entsperren des Users weiterhin gesperrt.
- **Status-Anzeige**: Badges „Aktiv“ / „Gesperrt“ in den Admin-Listen und im Besitzer-Dashboard; Filter nach Status in `/admin/sites` und `/admin/users`.
- **Datenmodell**: `sites.suspended` + `sites.suspended_at`, `users.suspended` + `users.suspended_at` (Boolean + Zeitstempel, kein Grundfeld). Migrationen: `20261124120000_add_suspended_to_sites.rb`, `20261124120100_add_suspended_to_users.rb`.
- Getestet in `rails/test/integration/suspension_test.rb`.

### 🇺🇸  
### Admin Area - “Read Comments” tab
- ⭐ Admins can view all comments and delete individual comments
### Admin Area - Settings tab
- ⭐ The admin area has been expanded to include a new tab with 5 sub tabs, providing direct access to several settings:**  
  
**Settings tab with toggles and input fields**  
### Global control of the following features:  
- Tab General  
  - Home page introduction block _enable/disable_
  - Dedicated legal notice page _enable/disable_
  - Cookie-Banner _enable/disable_
  - New user registration _enable/disable_
  - Login rate limiting _enable/disable_
  - Maximum login attempts per IP _number field_
  - Maximum failed attempts per email/username _number field_
  - Time window in minutes _number field_
- Tab Community   
  - Comment feature _enable/disable_
  - Wiki ratings _enable/disable_
  - Shoutbox _enable/disable_
- Tab Hub & Display  
  - Default theme on first visit (dropdown) _light/dark/auto_
  - Fix menu bar at the top while scrolling _enable/disable_
  - Maximum frontend width _input field_
  - Number of wikis per page in the Hub/Explore view _number field and +/-_
  - Enable and configure banner message _toggle, dropdown, text field_ 
  - Fix banner message at the top while scrolling _enable/disable_
- Tab Subscriptions  
  - Stripe subscription feature _enable/disable_
  - Gravatar/Libravatar _enable/disable_
  - Maximum number of tags allowed per page/wiki _number field and +/-_
- Tab Storage & Versions (Standard Plan; Premium Plan: visible only if subscriptions are active)
  - Max. versions (Free plan) _number field and +/-_
  - Max. versions (Standard plan) _number field and +/-_
  - Max. versions (Premium plan) _number field and +/-_
  - Max. versions (Tiddlyspot) _number field and +/-_
  - Retention: days for daily snapshots _number field (0 = off)_
  - Retention: pause between sessions in minutes _number field (0 = off)_
  - Retention: number of additional session snapshots _number field (0 = off)_
  - Details: **[Readme_History_Retention.md](Readme_History_Retention.md)**
  
  - Max. storage size per wiki (Free Plan) _number field and +/-_
  - Max. storage size per wiki (Standard Plan) _number field and +/-_
  - Max. storage size per wiki (Premium Plan) _number field and +/-_
  
  - Maximum storage size per account (Free-Plan) _Zahlenfeld und +/-_
  - Maximum storage size per account (Standard-Plan) _Zahlenfeld und +/-_
  - Maximum storage size per account (Premium-Plan) _Zahlenfeld und +/-_
- Tab Languages  
  - List of all languages, for system-wide activation/deactivation
  - Select default language (dropdown) _toggle_
  - A toggle switch for each language _on/off_
  - Icon to indicate the default language
  - Icon to indicate the currently selected language
    - (Disabling the default language, the current language, or all at once is prevented! (Flash messages))  
    - (It's possible to use a single language only, system wide.)  
    - (If there is only one system-wide language, there is no language selection menu in header.)  
  
- To add a new language: **See: [readme_add_new_language.md](readme_add_new_language.md)**

i18n support for all new admin texts and error messages  
Improved table headers in the admin lists (Sites & Users) with proper multilingual support  
  
All changed settings take effect immediately without requiring a restart.  

### Dedicated legal notice page (for operation in Europe)
- The page is available at `/imprint`: `rails/app/views/home/imprint.html.haml`.
- The footer link can be enabled or disabled in the admin area under **General tab → Special imprint page active**.
- The setting is read via `special_imprint_enabled` in `rails/lib/settings/features.rb` (default: enabled).
- The contact details in the legal notice are encoded as Unicode characters. This keeps them out of the source as plain text, which deters simple data collectors. It is not protection against targeted extraction.
- The page content (name, address, email) is a sample and must be replaced with your own details before productive use. The [eRecht24 imprint generator](https://www.e-recht24.de/impressum-generator.html) was used as a template.

### Login rate limiting (Admin → Settings → General)
- Protection for `POST /users/sign_in` via Rack::Attack, which runs before Rails.
- Two separate counters: **all login attempts per IP** and **failed attempts per email/username**. A successful sign-in clears the failure counter for that identity.
- Defaults: **3 attempts per IP**, **3 failures per identity**, **5 minute** window. The 4th attempt is rejected with HTTP 429 and `Retry-After`.
- All four values are configurable in the admin area (ranges: 1–100 attempts, 1–60 minutes). Turning the feature off disables both counters immediately.
- Counters use `Rails.cache`; with a `NullStore` (e.g. dev/test without caching) a `MemoryStore` is installed automatically.
- Covered by `rails/test/integration/login_rate_limit_test.rb`.

### Admin area – wiki and user suspension
**Admins can suspend individual wikis or entire user accounts and lift the suspension at any time.**
- **Wiki suspension** at `/admin/sites`: “Suspend 🚫” / “Unsuspend ✅” button directly in the list, plus a status filter.
- **User suspension** at `/admin/users` and `/admin/users/:id`: status, suspension timestamp and “Suspend user 🚫” / “Unsuspend ✅” button. The signed-in admin cannot suspend their **own** account.
- **Suspended wiki**: not served, saving is blocked and the wiki disappears from Hub/Explore.
- **Suspended user**: cannot log in (an already open session is dropped on the next request) and password reset emails are suppressed.
- **Derived suspension**: all wikis owned by the suspended user become unavailable without rewriting their records. Tspot sites have no own suspension flag and follow the owner's account only. Wikis suspended individually before the account suspension stay suspended after unsuspending the user.
- **Status display**: “Active” / “Suspended” badges in the admin lists and on the owner's dashboard; status filters on `/admin/sites` and `/admin/users`.
- **Data model**: `sites.suspended` + `sites.suspended_at`, `users.suspended` + `users.suspended_at` (boolean plus timestamp, no reason field). Migrations: `20261124120000_add_suspended_to_sites.rb`, `20261124120100_add_suspended_to_users.rb`.
- Covered by `rails/test/integration/suspension_test.rb`.
