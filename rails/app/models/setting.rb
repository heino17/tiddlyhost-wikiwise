# app/models/setting.rb
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: { case_sensitive: false }

  # Optional: Scope für aktive Settings
  scope :enabled, -> { where(enabled: true) }

  # Hilfsmethode zum Lesen (kompatibel mit alter Schreibweise)
  def self.enabled?(key, default: false)
    record = find_by(key: key.to_s)
    record ? record.enabled? : default   # .enabled? ist ActiveRecord-Methode
  end

  # Setter-Hilfsmethode
  def self.set_enabled(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.enabled = ActiveModel::Type::Boolean.new.cast(value)  # sicherer als !!
    record.save!
  end
end