class CreateWikiCollaborators < ActiveRecord::Migration[7.2]
  def change
    create_table :wiki_collaborators do |t|
      t.references :site, null: false, foreign_key: true

      t.string :name, null: false
      t.string :password_digest, null: false
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :wiki_collaborators, [:site_id, :name]
  end
end
