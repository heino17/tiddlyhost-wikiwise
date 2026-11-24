class AddSuspendedToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :suspended, :boolean, default: false, null: false
    add_column :sites, :suspended_at, :datetime
    add_index :sites, :suspended
  end
end
