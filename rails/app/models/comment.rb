class Comment < ApplicationRecord
  belongs_to :site, counter_cache: :comments_count
  belongs_to :user
  has_many :comment_votes, dependent: :destroy

  validates :body, presence: true

  def score
    comment_votes.sum(:value)
  end
end
