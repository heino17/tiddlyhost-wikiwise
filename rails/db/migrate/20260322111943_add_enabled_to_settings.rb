class AddEnabledToSettings < ActiveRecord::Migration[7.2]
  def up
    # Idempotent: CreateSettings legt "enabled" auf frischen DBs schon an,
    # daher nur hinzufügen, wenn die Spalte noch fehlt (alte DBs).
    add_column :settings, :enabled, :boolean, default: false, null: false unless column_exists?(:settings, :enabled)
  end

  def down
    remove_column :settings, :enabled if column_exists?(:settings, :enabled)
  end
end