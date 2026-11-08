🇩🇪 Deutsch | 🇬🇧 English

# 🇩🇪 Speicherverlauf und Aufbewahrung

Tiddlyhost-wikiwise speichert bei jedem Speichern des Wikis eine neue Version.
Damit der Speicherverlauf bei aktivem Autosave nicht schon nach wenigen Saves
„durchläuft“, gilt für User mit aktivierter Site-History eine gestaffelte
Aufbewahrung.

## Aufbewahrungsregeln

Behalten werden:

1. **Recent-Puffer:** die letzten `keep_count` Versionen dicht hintereinander.
   Sie ermöglichen das kurzfristige Zurücknehmen von Fehlern.
2. **Sitzungssicherungen:** die letzte Version einer Sitzung. Eine neue Sitzung
   beginnt, wenn zwischen zwei Saves mindestens
   `history_session_gap_minutes` Minuten liegen. Zusätzlich werden maximal
   `history_session_keep_count` Sitzungssicherungen aufbewahrt.
3. **Tagessicherungen:** die letzte Version eines Tages, maximal
   `history_daily_keep_days` Tage lang.
4. **Versionen mit Label:** alle gelabelten Versionen werden nie automatisch
   gelöscht – unabhängig von den anderen Fenstern.

Alles außerhalb dieser Fenster wird beim Pruning entfernt.

Wichtig:

- Die gestaffelte Aufbewahrung gilt nur für User mit `site_history`.
- Free-User ohne History behalten weiterhin nur die letzten
  `keep_count_free` Versionen.
- TiddlySpot-Sites bleiben beim einfachen `keep_count`-Verhalten.
- Die History-Seite zeigt alle behaltenen Versionen an.

## Manueller Wiederherstellungspunkt

Auf der History-Seite gibt es den Button **„Wiederherstellungspunkt setzen“**.

Er:

- erstellt sofort eine neue Version vom aktuellen Stand,
- versieht sie mit einem Label (Datum und Uhrzeit),
- schützt sie dadurch dauerhaft vor dem automatischen Pruning.

Gut geeignet vor riskanten Änderungen: erst einen Wiederherstellungspunkt
setzen, dann experimentieren. Der Punkt bleibt erhalten, auch wenn danach
viele weitere Saves erfolgen.

## Admin-Einstellungen

Im Admin-Bereich unter **Einstellungen → Speicher & Versionen**:

| Einstellung | Default | Bedeutung |
|---|---:|---|
| `keep_count_free` / `_standard` / `_premium` | 4 / 8 / 17 | Größe des Recent-Puffers bzw. der einfachen Aufbewahrung |
| `history_daily_keep_days` | 14 | Tage für Tagessicherungen; `0` deaktiviert sie |
| `history_session_gap_minutes` | 30 | Pause, ab der eine neue Sitzung beginnt; `0` deaktiviert Sitzungssicherungen |
| `history_session_keep_count` | 10 | Anzahl zusätzlicher Sitzungssicherungen; `0` deaktiviert sie |

Speicherhinweis: Jede Version belegt Speicher. Mit den Defaults ergeben sich
maximal etwa `keep_count + history_daily_keep_days +
history_session_keep_count` Versionen pro Wiki (z. B. 8 + 14 + 10 = 32).
Gelabelte Versionen kommen zusätzlich hinzu.

## Technische Hinweise

- Pruning: `WithSavedContent#prune_attachments_now` und
  `WithSavedContent#history_versions_to_keep`
- Manueller Punkt: `Site#create_restore_point!`
- Route: `POST /sites/:id/create_restore_point`
  (`create_restore_point_site_path`)
- Hintergrundjob: `PruneAttachmentsJob`
- Admin-Konfiguration: `AdminController#settings_config`
- Label-Schutz: `AttachmentLabel` bzw. `attachment_label` am
  ActiveStorage-Attachment

# 🇬🇧 Save history and retention

Tiddlyhost-wikiwise creates a new version every time a wiki is saved. So that
the history does not “run through” within a few saves while autosave is
active, users with site history enabled get a tiered retention policy.

## Retention rules

The following versions are kept:

1. **Recent buffer:** the newest `keep_count` versions, kept densely to allow
   short-term undo.
2. **Session snapshots:** the last version of an editing session. A new session
   starts when two saves are at least `history_session_gap_minutes` minutes
   apart. Up to `history_session_keep_count` additional session snapshots are
   kept.
3. **Daily snapshots:** the last version of each day, for up to
   `history_daily_keep_days` days.
4. **Labeled versions:** every version with a label is kept forever,
   independent of the other windows.

Everything outside these windows is removed during pruning.

Important:

- Tiered retention applies only to users with `site_history`.
- Free users without history still keep only the newest `keep_count_free`
  versions.
- TiddlySpot sites keep the simple `keep_count` behaviour.
- The history page shows every retained version.

## Manual restore point

The history page has a **“Create restore point”** button. It:

- immediately creates a new version from the current state,
- labels it with a date and time,
- therefore protects it permanently from automatic pruning.

This is useful before risky changes: create a restore point first, then
experiment. It survives many subsequent saves.

## Admin settings

In the admin area under **Settings → Storage & Versions**:

| Setting | Default | Meaning |
|---|---:|---|
| `keep_count_free` / `_standard` / `_premium` | 4 / 8 / 17 | Size of the recent buffer / simple retention |
| `history_daily_keep_days` | 14 | Days to keep daily snapshots; `0` disables them |
| `history_session_gap_minutes` | 30 | Pause after which a new session starts; `0` disables session snapshots |
| `history_session_keep_count` | 10 | Number of additional session snapshots; `0` disables them |

Storage note: every version consumes storage. With the defaults, a wiki keeps
at most about `keep_count + history_daily_keep_days +
history_session_keep_count` versions (e.g. 8 + 14 + 10 = 32). Labeled
versions are kept on top of that.

## Technical notes

- Pruning: `WithSavedContent#prune_attachments_now` and
  `WithSavedContent#history_versions_to_keep`
- Manual restore point: `Site#create_restore_point!`
- Route: `POST /sites/:id/create_restore_point`
  (`create_restore_point_site_path`)
- Background job: `PruneAttachmentsJob`
- Admin configuration: `AdminController#settings_config`
- Label protection: `AttachmentLabel` / `attachment_label` on the
  ActiveStorage attachment
