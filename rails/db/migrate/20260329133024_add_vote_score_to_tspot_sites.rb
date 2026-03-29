class AddVoteScoreToTspotSites < ActiveRecord::Migration[7.2]
  def change
    add_column :tspot_sites, :vote_score, :decimal
  end
end
