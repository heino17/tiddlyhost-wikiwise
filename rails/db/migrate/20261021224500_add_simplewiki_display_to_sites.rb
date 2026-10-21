class AddSimplewikiDisplayToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :display_name, :string
    add_column :sites, :subtitle, :string
  end
end
