### 🇩🇪 Tiddlyhost-wikiwise  
**+ rails I18n Sprach-Implementierung**  

- 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN - Schalter in menu bar

### Hier die **kurze Skizze**, was du tun musst, wenn du eine **neue Sprache** (z. B. Italienisch `it`) hinzufügen willst:

# So fügst du eine neue Sprache hinzu:

1. **In `app/helpers/application_helper.rb`**  
   Füge die neue Sprache in `available_locales` und `flag_emoji_for(locale)` hinzu:

```ruby
   def available_locales
     {
       de:     "Deutsch",
       en:     "English",
       ru:     "Русский",
       es:     "Español",
       fr:     "Français",
       ja:     "日本語",
       ko:     "한국어",
       zh_CN:  "简体中文",
       it:     "Italiano"          # ← neu
     }
   end

   def flag_emoji_for(locale)
     case locale.to_sym
     when :de     then "🇩🇪"
     when :en     then "🇺🇸"
     when :ru     then "🇷🇺"
     when :es     then "🇪🇸"
     when :fr     then "🇫🇷"
     when :ja     then "🇯🇵"
     when :ko     then "🇰🇷"
     when :zh_CN  then "🇨🇳"
     else "🌍"
     end
   end
```

2. **Flagge hinzufügen** (in derselben Datei):

```ruby
   def flag_emoji_for(locale)
     case locale.to_sym
     when :it then "🇮🇹"          # ← neu
     # ... rest bleibt gleich
     end
   end
```

3. **Übersetzungen in allen yml-Dateien** (de.yml, en.yml, ru.yml usw.):

```yaml
   admin:
     locales:
       it:
         label: "Italienisch aktivieren"
         description: "Italienische Sprache in der gesamten Anwendung verfügbar machen"
```

4. In `language_switcher_links` und `language_name` wird sie automatisch mit übernommen.

5. Zum Schluß noch schnell 25 Sprachdateien übersetzen :)
  - einfach einen vorhandenen Orner, vorzugsweise 'en', kopieren, umbenennen, übersetzen

---

**Fazit:**  
Du musst **nur 5 Stellen** anfassen:
- `application_helper.rb` (3×)
- Alle Übersetzungsdateien (eine neue Sektion pro Datei)
- Die Sprachdateien seibst übersetzen 


### 🇺🇸 Tiddlyhost-wikiwise  
**+ rails I18n Language implementation**  

- 🇬🇧 EN, 🇩🇪 DE, 🇷🇺 RU, 🇪🇸 ES, 🇫🇷 FR, 🇯🇵 JP, 🇰🇷 KR, 🇨🇳 zh-CN - Schalter in menu bar  

### Here is a **brief overview** of what you need to do if you want to add a **new language** (e.g., Italian `it`):  

# Here's how to add a new language:  

1. **In `app/helpers/application_helper.rb`**  
   Add the new language to `available_locales` and `flag_emoji_for(locale)`:  

```ruby
   def available_locales
     {
       de:     "Deutsch",
       en:     "English",
       ru:     "Русский",
       es:     "Español",
       fr:     "Français",
       ja:     "日本語",
       ko:     "한국어",
       zh_CN:  "简体中文",
       it:     "Italiano"          # ← new
     }
   end

   def flag_emoji_for(locale)
     case locale.to_sym
     when :de     then "🇩🇪"
     when :en     then "🇺🇸"
     when :ru     then "🇷🇺"
     when :es     then "🇪🇸"
     when :fr     then "🇫🇷"
     when :ja     then "🇯🇵"
     when :ko     then "🇰🇷"
     when :zh_CN  then "🇨🇳"
     else "🌍"
     end
   end
```

2. **Add a flag** (in the same file):  

   ```ruby
   def flag_emoji_for(locale)
     case locale.to_sym
     when :it then "🇮🇹"          # ← new
     # ... The rest remains the same
     end
   end
   ```

3. **Translations in all YML files** (de.yml, en.yml, ru.yml, etc.):  

```yaml
   admin:
     locales:
       it:
         label: "Activate Italian"
         description: "Make the Italian language available throughout the app"
```

4. In `language_switcher_links` and `language_name` it will be automatically included.

5. Finally, just quickly translate 25 language files :)  
  - Simply copy an existing folder (preferably ‘en’), rename it, and translate it  

---

**Conclusion:**  
You only need to make changes in **5 places**:  
- `application_helper.rb` (3×)  
- All translation files (one new section per file)  
- Translate the language files yourself   



### Lizenz

Tiddlyhost ist eine Open-Source-Software. Sie verwendet eine BSD-Lizenz. Siehe
[LICENSE.md](LICENSE.md).
