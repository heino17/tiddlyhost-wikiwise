class CreateShoutboxMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :shoutbox_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.timestamps
    end

    # Index für schnelle Abfragen der neuesten Nachrichten
    add_index :shoutbox_messages, :created_at
  end
end
