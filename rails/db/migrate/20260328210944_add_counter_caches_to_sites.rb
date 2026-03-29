class AddCounterCachesToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :votes_count, :integer, default: 0, null: false
    add_column :sites, :comments_count, :integer, default: 0, null: false

    # Indexe für schnelle Sortierung (sehr empfohlen)
    add_index :sites, :votes_count
    add_index :sites, :comments_count
  end
end