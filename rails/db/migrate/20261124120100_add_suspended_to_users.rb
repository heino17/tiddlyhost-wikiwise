class AddSuspendedToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :suspended, :boolean, default: false, null: false
    add_column :users, :suspended_at, :datetime
    add_index :users, :suspended
  end
end
