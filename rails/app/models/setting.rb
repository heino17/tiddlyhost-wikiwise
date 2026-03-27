# app/models/setting.rb
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # ==================== Boolean Settings ====================
  def self.enabled?(key, default: false)
    record = find_by(key: key.to_s)
    record ? record.enabled : default
  end

  def self.set_enabled(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.enabled = ActiveModel::Type::Boolean.new.cast(value)
    record.save!
  end

  # ==================== Integer / String Values ====================
  def self.value_for(key, default: nil)
    record = find_by(key: key.to_s)
    return default unless record

    # Wenn value gef?llt ist ¡æ verwenden (bevorzugt)
    if record.value.present? && record.value != 'false'
      record.value.to_i
    else
      # Fallback auf enabled oder default
      record.enabled ? 1 : default
    end
  end

  def self.set_value(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.value = value.to_s.strip
    record.save!
  end
end