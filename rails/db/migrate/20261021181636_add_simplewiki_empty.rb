class AddSimplewikiEmpty < ActiveRecord::Migration[7.2]
  def up
    # The empties sequence can lag behind when rows were created with explicit
    # ids (seeds/migrations), which would make the insert below collide on id 1.
    max_id = Empty.maximum(:id)
    if max_id
      connection.execute("SELECT setval('#{Empty.sequence_name}', #{max_id}, true)")
    else
      connection.execute("SELECT setval('#{Empty.sequence_name}', 1, false)")
    end

    Empty.find_or_create_by(name: 'simple') do |e|
      e.title = 'SimpleWiki'
      e.description = 'A simple single-page wiki for text pages, focused on ease of
        use and a clean data format.'.squish
      e.enabled = true
      e.primary = true
      e.display_order = 26
      e.info_link = 'https://github.com/heino17/simplewiki'
      e.tooltip = 'A lightweight wiki made of text pages. Saves are small because
        the content is stored as a separate data island.'.squish
    end.update(enabled: true, primary: true) # Make sure it's enabled in case you did a rollback
  end

  def down
    # Disable it but don't delete it since there might be sites using it
    Empty.find_by_name('simple').update(enabled: false)
  end
end
