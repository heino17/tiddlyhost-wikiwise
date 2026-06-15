class AddLastCollabSavedToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :last_collab_saved_by, :string
    add_column :sites, :last_collab_saved_at, :datetime
  end
end
