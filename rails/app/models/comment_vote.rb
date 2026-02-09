class CommentVote < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :value, inclusion: { in: [-1, 1] }
end
