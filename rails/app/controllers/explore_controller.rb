class ExploreController < HubController
  private

  def set_default_title
    @thing_name = 'Site'
    @default_title = 'Schaufenster'
    @explanation_text = %(
      Entdecke die Inhalte, die von Tiddlyhost-Nutzern erstellt und geteilt wurden.
    ).squish
  end
end
