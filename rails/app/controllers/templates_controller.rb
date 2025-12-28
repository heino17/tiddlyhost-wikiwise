class TemplatesController < HubController
  private

  def set_default_title
    @thing_name = 'Template'
    @default_title = 'Vorlagen'
    @explanation_text = %(
      Vorlagen sind nützliche oder interessante angepasste Versionen von TiddlyWiki, 
      die von Tiddlyhost-Benutzern erstellt wurden, die Du kopieren und für Dich selbst verwenden kannst. 
      Klicke auf „Klonen”, um eine Website auf Tiddlyhost unter Verwendung einer Vorlage zu erstellen, 
      oder klicke auf „Herunterladen”, um eine Kopie herunterzuladen und lokal zu verwenden.
    ).squish
  end
end
