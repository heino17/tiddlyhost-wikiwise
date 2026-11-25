🇩🇪 Deutsch und Amerikanisch 🇺🇸  
German and American  

# 🇩🇪 **Admin‑Bereich – Benutzerverwaltung erweitert**

**Die Benutzerverwaltung wurde für die Möglichkeit geöffnet, beliebig viele Benutzer- oder Adminkonten durch den Admin zu erstellen, unabhängig von der Einrichtung eines Zahlungssystems**  

**Der Admin hat uneingeschränkten Zugriff auf die Daten und Einstellungen eines Benutzer-Kontos!**

## 1. **Benutzerverwaltung**
- **Benutzer-Kontendetails anzeigen**  
- **Benutzer-Konto neu erstellen**  
- **Benutzer-Konto bearbeiten**  
- **Benutzer-Konto löschen**  
- **Benutzer-Konto sperren / entsperren**
---

### 2. **Benutzer-Kontendetails**
- **Benutzerdaten anzeigen**:
  - Basisdaten (Name, eMail, Benutzername, Zugriffsebene)
  - Profilbild (eigenes Bild des Benutzers; im Admin-Bereich nur sichtbar, nicht änderbar)
  - Aktivität (Letzter Login, Anzahl der Logins, Erstellt, Bestätigt)
  - Status (Aktiv / Gesperrt, ggf. Zeitpunkt der Sperrung)
  - Inhalte (Anzahl der Seiten/Wikis, Anzahl Seiten in Hub-Ansicht)
---

## 3. **Benutzer-Konto neu erstellen**
- Sinnvoll, wenn das öffentliche Registrieren/Konto erstellen auf der Seite deaktiviert ist
- Grüner Link-Button im Admin-Tab-"Benutzer"  
- Basisdaten erstellen (Name, eMail, Benutzername, Zugriffsebene, Passwort)  
- Passwort‑Generator (16‑Zeichen, sichere Zeichenmenge)  
  - Separate Klartext‑Passwort‑Anzeige beim Tippen (Gut für copy&paste)  
  - Passwort‑Stärkeanzeige mit 6 Stufen (Schwach, ..., Sehr Stark etc.)  
**Wenn der Admin ein neues Konto erstellt, ist das Konto sofort aktiviert/bestätigt!**
**EMail-Bestätigungs-Link per "make signup-link" für localhost ist nicht mehr notwendig, Login sofort möglich!**
---

### 4. **Benutzer-Konto bearbeiten**  
- **Basisdaten bearbeiten**:  
  - (Name, eMail, Benutzername, Zugriffsebene, Passwort)  
  - Zugriffsebene `basic` oder `superuser` wählbar  
  - Passwort‑Generator (16‑Zeichen, sichere Zeichenmenge)  
    - Separate Klartext‑Passwort‑Anzeige beim Tippen (Gut für copy&paste)  
    - Passwort‑Stärkeanzeige mit 6 Stufen (Schwach, Gut, Stark etc.)  
    - Passworteingabe beim Bearbeiten ist optional  
---

### 5. **Benutzer-Konto löschen**  
- **Ein Admin kann jedes Benutzer-Konto löschen!**:  
- **Ein Admin kann NICHT sein eigenes superuser-Konto löschen während er mit diesem angemeldet ist!**  
- **Ein Admin kann die Zugriffsebene seines superuser-Kontos NICHT auf basic-Konto schalten!**  
---  

### 6. **Benutzer- und Wiki-Sperre**
- **Einzelne Wikis sperren/entsperren** im Admin-Tab „Sites“ (`/admin/sites`)
- **Benutzerkonten sperren/entsperren** im Admin-Tab „Benutzer“ (`/admin/users`) oder in den Kontodetails (`/admin/users/:id`)
- **Selbstschutz**: Der angemeldete Admin kann sein eigenes Konto nicht sperren.
- **Wiki-Sperre**: Das Wiki wird nicht ausgeliefert, Speichern ist blockiert und es erscheint nicht mehr in Hub/Explore.
- **User-Sperre**: Kein Login, keine Passwort-Reset-Mails; eine bereits offene Session verliert beim nächsten Request den Zugriff.
- **Abgeleitete Sperre**: Alle Wikis des gesperrten Users sind mitgesperrt, ohne dass deren Datensätze verändert werden. Tspot-Sites haben kein eigenes Sperrflag und folgen nur der User-Sperre. Bereits einzeln gesperrte Wikis bleiben nach dem Entsperren des Users gesperrt.
- **Status**: Badges „Aktiv“ / „Gesperrt“ in den Admin-Listen und im Besitzer-Dashboard; Statusfilter in `/admin/sites` und `/admin/users`.
- **Speicherung**: Boolean-Flag plus `suspended_at` bei `users` und `sites` – kein zusätzliches Grundfeld. Details: [Readme-Admin-tab.md](Readme-Admin-tab.md)
---

### 7. **Erscheinungsbild und Allgemeines**
- Ein paar UTF‑8‑Icons  
- Controller‑Flash‑Meldungen  
- Admin-Tab-"Sites": `_user_info`-Bereich für die Einzelansicht eines Benutzers etwas angepasst  
  - Buttons für "Zurück zur Auswahl", "Benutzerdaten anzeigen" und "Hub-Seiten des Benutzers anzeigen"  
  - Anzeige der Tiddlyspot-Seiten wurde berücksichtigt, aber nicht getestet  
- Keine Hardcoded‑Strings mehr im Admin‑Bereich  
- Profilbild in der Admin-Benutzertabelle und in den Kontodetails sichtbar; eigene Bilder werden beim Speichern bei Bedarf auf max. 256×256 px verkleinert (max. 100 KB). Externe Avatare (Gravatar/Libravatar) bleiben optional.
- In SimpleWiki-Wikis erscheint das Profilbild des Besitzers im Kopf anstelle von 👤. Der Server liefert dazu in `/simplewiki/status` einen Pfad auf dem eigenen Server; die Oberfläche akzeptiert nur solche Pfade und zeigt das Bild nur, wenn der Besitzer angemeldet ist.
- Wenn sich ein Benutzer einloggt, landet er in der seiner Seitenübersicht  
- Wenn sich ein Admin einloggt, landet er sofort in Admin-Bereich  
---

### 8. **Internationalisierung (i18n)**
- Vollständige Übersetzung in **8 Sprachen**:
  - 🇺🇸 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN
---

### 9. **Zu Abonnements / Stripe-Integration**
**Es wurde versucht, die Anbindung an ein Zahlungssystem wie Stripe, nicht zu behindern...**
  - Bei deaktivierter "Abonnements / Stripe-Integration" übergeht die App sämtlichen Kontakt zum Online-Zahlungssystem.  
  - Bei aktivierter "Abonnements / Stripe-Integration", sollte die Verbindung zum Zahlungssystem, entsprechend der Einstellungen in der settings.yml, möglichen sein!
  - Ob "Abonnements / Stripe-Integration" aktiviert oder deaktiviert: Wenn keine Verbindung zum Zahlungssytem erkannt wird, erhält der jeder neue Benutzer ein kostenloses Free-Konto im System!
  - Überarbeitung der Zahlungsfunktion bei Anbindung sicherlich notwendig!
---

# 🇺🇸 **Admin Area – Extended User Management**

**User management has been updated to allow the admin to create any number of user or admin accounts, independently of setting up a payment system.**

**The admin has full unrestricted access to all user account data and settings!**

## 1. **User Management**
- **View user account details**  
- **Create new user accounts**  
- **Edit user accounts**  
- **Delete user accounts**  
- **Suspend / unsuspend user accounts**
---

### 2. **User Account Details**
- **Display user data**
  - Basic information (name, email, username, access level)
  - Profile picture (the user's own image; visible only in the admin area, not editable there)
  - Activity (last login, number of logins, created, confirmed)
  - Status (Active / Suspended, including the suspension timestamp)
  - Content (number of sites/wikis, number of sites in Hub view)
---

## 3. **Create New User Account**
- Particularly useful when public registration is disabled
- Green "Create User" button in the Admin "Users" tab
- Create basic data (name, email, username, access level, password)
- Password generator (16 characters, secure character set)
  - Separate plain-text password display while typing (great for copy & paste)
  - Password strength indicator with 6 levels (Weak, Good, Strong, etc.)
  
**When the admin creates a new account, it is immediately activated and confirmed!**  
**→ The email confirmation link generated by “make signup-link” for localhost is no longer required; you can log in immediately!**
---

### 4. **Edit User Account**
- **Edit basic data**
  - (Name, email, username, access level, password)
  - Access level selectable between `basic` and `superuser`
  - Password generator (16 characters, secure character set)
    - Separate plain-text password display while typing (great for copy & paste)
    - Password strength indicator with 6 levels (Weak, ..., Very Strong, etc.)
    - Password entry is optional when editing
---

### 5. **Delete User Account**  
- **Administrators can delete any user account!**:  
- **Administrators cannot delete their own superuser account while logged in with that account!****
- **Administrators cannot downgrade their own superuser account to a basic account!**
---

### 6. **User and Site Suspension**
- **Suspend/unsuspend individual wikis** in the admin “Sites” tab (`/admin/sites`)
- **Suspend/unsuspend user accounts** in the admin “Users” tab (`/admin/users`) or on the account details page (`/admin/users/:id`)
- **Self-protection**: The signed-in admin cannot suspend their own account.
- **Suspended wiki**: not served, saving is blocked and it no longer appears in Hub/Explore.
- **Suspended user**: no login, no password reset emails; an already open session loses access on the next request.
- **Derived suspension**: all of the user's wikis are suspended as well without rewriting their records. Tspot sites have no own suspension flag and follow the owner's account only. Wikis suspended individually beforehand remain suspended after the user is unsuspended.
- **Status**: “Active” / “Suspended” badges in the admin lists and on the owner's dashboard; status filters on `/admin/sites` and `/admin/users`.
- **Storage**: boolean flag plus `suspended_at` on `users` and `sites` – no separate reason field. Details: [Readme-Admin-tab.md](Readme-Admin-tab.md)
---

### 7. **Appearance & General Improvements**
- Added several UTF-8 icons
- Controller flash messages
- Admin tab "Sites": Adjusted `_user_info` section for individual user view
  - Buttons for "Back to selection", "Show user details" and "Show user's Hub sites"
  - The rendering of Tiddlyspot pages has been taken into account, but not tested.
- No more hardcoded strings in the admin area
- Profile pictures are shown in the admin user table and account details; oversized uploads are automatically scaled down to max. 256×256 px (max. 100 KB). External avatars (Gravatar/Libravatar) remain optional.
- In SimpleWiki sites the owner's profile picture replaces 👤 in the header. `/simplewiki/status` sends a same-origin path; the shell accepts only such paths and shows the picture only while the owner is signed in.
- When a user logs in, they land on their page overview.
- When an administrator logs in, they are immediately taken to the admin area.

---

### 8. **Internationalization (i18n)**
- Fully translated into **8 languages**:
  - 🇺🇸 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN
---

### 9. **Regarding Subscriptions / Stripe Integration**
**Care was taken not to obstruct a possible connection to a payment system such as Stripe...**

- When "Subscriptions / Stripe Integration" is **disabled**, the app completely bypasses any contact with the online payment system.
- When "Subscriptions / Stripe Integration" is **enabled**, the connection to the payment system should work according to the settings in `settings.yml`.
- Regardless of whether the integration is active or not: If no connection to a payment system is detected, every new user automatically receives a free **Free Plan** account.
- A later revision of the payment functionality will likely be necessary once Stripe is fully integrated.
---
