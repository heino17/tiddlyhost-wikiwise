class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    unless table_exists?(:settings)
      create_table :settings do |t|
        t.string :key, null: false
        t.text :value
        t.boolean :enabled, default: false
        t.timestamps
      end
      add_index :settings, :key, unique: true
    end
  end
end