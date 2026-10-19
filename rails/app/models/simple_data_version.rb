class SimpleDataVersion < ApplicationRecord
  belongs_to :site

  validates :json, presence: true
end
