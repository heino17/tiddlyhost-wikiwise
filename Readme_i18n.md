```markdown
### Internationalization / Multi-Language Support (I18n)

Implemented together with Grok (as of January 2026)

**Main achievements:**
- Fully working language switch (English ↔ German) with persistence via session cookie
- First page load reliably starts in English (:en as default)
- Browser language is no longer automatically applied on first visit
- Clean, maintainable structure for easily adding more languages later (fr, es, …)

**Most important changed / added files:**

- `config/application.rb`
  - `config.i18n.default_locale = :en`
  - `config.i18n.available_locales = [:en, :de]`

- `app/controllers/application_controller.rb`
  - `before_action :set_locale`
  - Improved `set_locale` method (only persist when user explicitly chooses via switcher; otherwise use default)

- `config/locales/`
  - `en.yml` & `de.yml` (base translations + app-specific keys)

- `app/views/layouts/_header.html.haml`
  - Language dropdown showing current language + switch links (using `url_for(locale: …)`)
  - (future extension: flag icons via flag-icons CSS library possible)

- Various views & controllers (examples):
  - `app/views/subscription/_plans.html.haml` → dynamic title (Pricing / Subscription plans)
  - `app/controllers/explore_controller.rb` → translated explanation texts

**Current status (January 2026):**
- Stable with 0 test failures (at least when running in :en)
- Large portion of UI text already translated (de.yml keeps growing)
- Very solid foundation for adding more languages

+++++++++++++++++ German Readme ++++++++++++++++++

```markdown
### Mehrsprachigkeit / Internationalisierung (I18n)

Gemeinsam mit Grok umgesetzt (Stand: Januar 2026)

**Wichtigste erreichte Ziele:**
- Vollständig funktionsfähige Sprachumschaltung (en/de) mit Persistenz über Session-Cookie
- Erster Seitenaufruf startet zuverlässig auf Englisch (:en als Default)
- Browser-Sprache wird nur noch als Vorschlag betrachtet, nicht automatisch übernommen
- Saubere, wartungsfreundliche Struktur für zukünftige Sprachen (fr, es, …)

**Wichtigste geänderte / hinzugefügte Dateien:**

- `config/application.rb`
  - `config.i18n.default_locale = :en`
  - `config.i18n.available_locales = [:en, :de]`

- `app/controllers/application_controller.rb`
  - `before_action :set_locale`
  - Angepasste `set_locale`-Methode (expliziter Wechsel → merken, sonst Default)

- `config/locales/`
  - `en.yml` & `de.yml` (Basis-Übersetzungen + App-spezifische Keys)

- `app/views/layouts/_header.html.haml`
  - Sprach-Dropdown mit aktueller Sprache + Links (url_for(locale: …))
  - (später: Flag-Icons via flag-icons CSS möglich)

- Diverse Views & Controller (Beispiele):
  - `app/views/subscription/_plans.html.haml` → dynamischer Titel (Pricing / Subscription plans)
  - `app/controllers/explore_controller.rb` → übersetzte Erklärungstexte

**Aktueller Status (Januar 2026):**
- Funktioniert stabil mit 0 Fehlern in den Tests (bei :en)
- Großteil der UI-Texte bereits übersetzt (de.yml wächst kontinuierlich)
- Sehr gute Basis für weitere Sprachen vorhanden