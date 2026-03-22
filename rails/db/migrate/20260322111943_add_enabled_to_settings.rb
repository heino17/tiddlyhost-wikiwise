class AddEnabledToSettings < ActiveRecord::Migration[7.2]  # oder deine Rails-Version
  def change
    add_column :settings, :enabled, :boolean, default: false, null: false
  end
end