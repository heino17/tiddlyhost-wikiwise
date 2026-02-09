class CreateSiteVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :site_votes do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Für Sterne: 1-5; für +1/-1: -1 oder 1
      t.integer :value, null: false, default: 3  # Default für Sterne; für +1/-1: 1

      t.timestamps
    end

    # Ein User darf jede Site nur einmal voten
    add_index :site_votes, [:user_id, :site_id], unique: true
  end
end
