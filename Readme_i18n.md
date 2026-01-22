# Internationalization / Multi-Language Support (I18n)

# The fun factor
## # "Key findings":

- Fully working language switch *🇬🇧 English ↔ 🇩🇪 German ↔ 🇪🇸 Spanish ↔  🇫🇷 French* with persistence via session cookie
- Clean, lightweight option for future languages (it, pl, ru, gr, etc.)
- First page view reliably starts in English (:en as default, can be changed)
- Browser language is considered a suggestion, not automatically adopted (can be changed)
- HTML ISO language codes change according to language  
`<html data-theme-mode="<%= thememode %>" data-bs-theme="<%= theme_mode %>" lang="<%= t('iso_language_code') %>">`  
    - If your browser detects that the page is written in a language other than your preferred language, it will display an icon or button that allows you to translate the entire page into your language.  
    - The lang attribute with ISO language code (e.g., lang="de", lang="en") helps screen readers read the text aloud in the correct language, pronunciation, and intonation.
    - Search engines can index 4 languages:
      - host.domain/?locale=en
      - host.domain/?locale=de
      - host.domain/?locale=es
      - host.domain/?locale=fr
 
 - *I don't really need it, but it's fun, so I'll do it, right? :)*

### # Schematic modification:

  - `rails/Gemfile` 
    - Inserts
      -  gem 'rails-i18n'
      -  gem 'i18n-js', '~> 4.2', '>= 4.2.4'

- `config/application.rb`
    - `config.i18n.available_locales = [:en, :de, :es , :fr]` 
      - (other or all country ISO codes possible)
    - `config.i18n.default_locale = :en`
      - (default when the page is loaded for the first time)

  - `config/app/helpers/application_helpers.rb`
    - loading the text links and flags into the switch (can be easily expanded))

- `app/controllers/application_controller.rb`
  - `before_action :set_locale`
  - `set_locale`- method:
      - The default language when the page is first loaded is :en
      - Browser language is ignored, but can be enabled optionally
      - The selected language remains active until the next switch, but can optionally revert to :en upon logout

- `config/locales/`
  - `rails i18n locales` (loaded as .yml from config/locales/, - makes it easier to make changes)
  - `en.yml`, `de.yml`, `es.yml` & `fr.yml` (as startup files)
  - `Translations` in subfolders

- `app/views/layouts/_header.html.haml`
  - `Language dropdown` with current language + links (url_for(locale: …))
  - `SVG flag icons` are loaded from the app/assets/images/flags/4x3/ folder

- `Replace various texts and hard codes in views & controllers` 
  - replaced with t(“key”) and moved to translation files (.yml)
  - minor adjustments to the code for compatibility
  -  approximately 60 existing files edited (almost complete, the “Pricing” section is still missing)
  -  80 language files created

### # Current status (January 2026):
- Works stably with 0 errors in tests (with :en as default)
- 96% of UI texts and words already translated (.yml language files still need to be organized...)
- Very good basis for additional languages available
- Mother repository is https://github.com/tiddlyhost/tiddlyhost-com

  ## ***That was fun! :)***

+++++++++++++++++ German Readme ++++++++++++++++++

# Mehrsprachigkeit / Internationalisierung (I18n)

## Der Spaßfaktor
## # "Schlüssel-Erkenntnisse":

- Vollständig funktionsfähige Sprachumschaltung  *🇬🇧 Englisch ↔ 🇩🇪 Deutsch ↔ 🇪🇸 Spanisch ↔ 🇫🇷 Französisch)* mit Persistenz über Session-Cookie
- Saubere, leichtgewichtige Möglichkeit für zukünftige Sprachen (it, pl, ru, gr, …)
- Erster Seitenaufruf startet zuverlässig auf Englisch (:en als Default, kann geändert werden)
- Browser-Sprache wird als Vorschlag betrachtet, nicht automatisch übernommen (Änderung möglich)
- HTML-ISO-Sprachcodes wechseln nach Sprache  
`<html data-theme-mode="<%= thememode %>" data-bs-theme="<%= theme_mode %>" lang="<%= t('iso_language_code') %>">`  
    - Wenn dein Browser erkennt, dass die Seite in einer anderen Sprache als deiner bevorzugten Sprache verfasst ist, zeigt er ein Symbol oder eine Schaltfläche an, mit der Du die Seite vollständig in deine Sprache übersetzen kannst.  
    - Das lang-Attribut mit ISO-Sprachcode (z. B. lang="de", lang="en") hilft Screenreadern, den Text in der richtigen Sprache, Aussprache und Betonung vorzulesen.
    - Suchmaschinen können 4 Sprachen indexieren:
      - host.domain/?locale=en  
      - host.domain/?locale=de  
      - host.domain/?locale=es  
      - host.domain/?locale=fr  

- *Ich brauche es eigentlich nicht, aber es macht Spaß, also mach ich's, oder?. :)*

### # Schematischer Umbau:
 
  - `rails/Gemfile` inserts
    -  gem 'rails-i18n'
    -  gem 'i18n-js', '~> 4.2', '>= 4.2.4'

  - `config/application.rb`
    - `config.i18n.available_locales = [:en, :de, :es , :fr]` 
      - (weitere bzw. alle Länder-iso-codes möglich)
    - `config.i18n.default_locale = :en`
      - (Standard beim ersten Laden der Seite)

  - `config/app/helpers/application_helpers.rb`
    - laden der Text-Links und Flaggen in den Schalter (Kann leicht erweitert werden)

- `app/controllers/application_controller.rb`
  - `before_action :set_locale`
  - `set_locale`- Methode:
     - Standardsprache beim ersten Laden der Seite ist :en
     - BrowserSprache wird ignoriert, kann optional aktiviert werden
     - Gewählte Sprache bleibt bis zum nächsten Umschalten aktiv, kann optional beim logout auf :en zurückfallen

- `config/locales/`
  - `rails i18n locales` (als .yml aus config/locales/ geladen, - erleichtert Eingriffe)
  - `en.yml`, `de.yml`, `es.yml` & `fr.yml` (als Startdateien)
  - `Übersetzungen` in Unterordnern

- `app/views/layouts/_header.html.haml`
  - `Sprach-Dropdown` mit aktueller Sprache + Links (url_for(locale: …))
  - `SVG-Flaggen-Symbole` werden aus dem Ordner app/assets/images/flags/4x3/ geladen

- `Diverse Texte und hard-codes in Views & Controllern ersetzen` 
  - durch t("key") ersetzt und in Übersetzungsdateien (.yml) ausgelagert
  - kleine Anpassungen im Code für Kompatibilität
  -  ca. 60 vorhandene Dateien bearbeitet (fast vollständig, der "Pricing"-Teil fehlt noch)
  -  80 Sprachdateien erstellt

### # Aktueller Status (Januar 2026):
- Funktioniert stabil mit 0 Fehlern in den Tests (bei :en als Standard)
- 96% der UI-Texte und Worte bereits übersetzt (.yml-Sprachdateien sind noch zu ordnen...)
- Sehr gute Basis für weitere Sprachen vorhanden
- Mutter-Reository ist https://github.com/tiddlyhost/tiddlyhost-com

  ## **Hat Spaß gemacht! :)**
