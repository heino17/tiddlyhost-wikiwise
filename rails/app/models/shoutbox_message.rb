class ShoutboxMessage < ApplicationRecord
  belongs_to :user

  validates :message, presence: true, length: { maximum: 120 }

  # Standardmäßig neueste zuerst
  default_scope { order(created_at: :desc) }

  # Nach Erstellung alte Nachrichten automatisch löschen (behalte nur die letzten 500)
  after_create :prune_old_messages

  private

  def prune_old_messages
    max_stored = 500
    if ShoutboxMessage.count > max_stored
      ShoutboxMessage.offset(max_stored).destroy_all
    end
  end
end