class CreateCommentVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :comment_votes do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # +1 = upvote, -1 = downvote
      t.integer :value, null: false, default: 1

      t.timestamps
    end

    # Ein User darf jeden Kommentar nur einmal voten
    add_index :comment_votes, [:user_id, :comment_id], unique: true
  end
end
