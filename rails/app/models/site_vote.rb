class SiteVote < ApplicationRecord
  belongs_to :site
  belongs_to :user

  # Für Sterne:
  validates :value, inclusion: { in: 1..5 }
  # Für +1/-1: validates :value, inclusion: { in: [-1, 1] }
end