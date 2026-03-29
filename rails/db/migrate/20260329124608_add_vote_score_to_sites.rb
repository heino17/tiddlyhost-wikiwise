class AddVoteScoreToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :vote_score, :decimal, precision: 3, scale: 1, default: 0.0
    add_index :sites, :vote_score
  end
end