class SiteVote < ApplicationRecord
  belongs_to :site, counter_cache: :votes_count
  belongs_to :user

  validates :value, inclusion: { in: 1..5 }
  # Für +1/-1: validates :value, inclusion: { in: [-1, 1] }

  # Zuverlässige Counter-Aktualisierung
  after_create   :update_site_vote_count
  after_update   :update_site_vote_count
  after_destroy  :update_site_vote_count

  private

  def update_site_vote_count
    return unless site_id.present?
    
    # 1. Counter-Cache aktualisieren
    Site.reset_counters(site_id, :site_votes)
    
    # 2. Vote-Score aktualisieren (ohne zusätzliche Callbacks)
    Site.find(site_id)&.update_vote_score
  end
end