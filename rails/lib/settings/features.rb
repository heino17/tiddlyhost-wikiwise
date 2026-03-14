module Settings::Features
  module_function

  def admin_enabled?(user)
    user&.is_admin?
  end

  def site_history_enabled?(user)
    user&.is_admin? || user&.has_subscription?
  end

  def site_history_preview_enabled?(user)
    subscriptions_enabled?(user) && !site_history_enabled?(user)
  end

  def subscriptions_enabled?(_user = nil)
    true
  end

  def redirect_tspot_to_url_enabled?(user)
    user&.is_admin? || user&.has_subscription?
  end

  def startpage_introduction_block_enabled?
    # Variante A – schnell & hartcodiert zum Testen
    false   # true / false

    # Variante B – später aus DB (empfohlen)
    # GlobalSetting.startpage_introduction_block_enabled?   # oder Setting[:startpage_introduction_block_enabled]

    # Variante C – aus Rails config (deploy nötig bei Änderung)
    # Rails.application.config.x.startpage_introduction_block_enabled || false
  end

  def special_imprint_enabled?
    # Variante A – schnell & hartcodiert zum Testen
    false   # true / false

    # Variante B – später aus DB (empfohlen)
    # GlobalSetting.special_imprint_enabled?   # oder Setting[:special_imprint_enabled]

    # Variante C – aus Rails config (deploy nötig bei Änderung)
    # Rails.application.config.x.special_imprint_enabled || false
  end

  def registration_enabled?
    # Variante A – schnell & hartcodiert zum Testen
    true   # true / false

    # Variante B – später aus DB (empfohlen)
    # GlobalSetting.registration_enabled?   # oder Setting[:registration_enabled]

    # Variante C – aus Rails config (deploy nötig bei Änderung)
    # Rails.application.config.x.registration_enabled || false
  end
end