class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.text :body, null: false
      t.datetime :edited_at

      t.timestamps
    end

    # Ein User darf pro Site nur einen Kommentar haben
    add_index :comments, [:user_id, :site_id], unique: true
  end
end
