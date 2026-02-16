class Comment < ApplicationRecord
  belongs_to :site
  belongs_to :user
  has_many :comment_votes, dependent: :destroy

  validates :body, presence: true

  # Für die Anzeige: Summe aller Votes
  def score
    comment_votes.sum(:value)
  end
end
