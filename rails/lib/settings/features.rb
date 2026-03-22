module Settings::Features
  require_dependency 'setting'
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
    Setting.enabled?(:startpage_introduction_block_enabled, default: true)
  end

  def special_imprint_enabled?
    Setting.enabled?(:special_imprint_enabled, default: true)
  end

  def registration_enabled?
    Setting.enabled?(:registration_enabled, default: false)
  end

  def comments_enabled?
    Setting.enabled?(:comments_enabled, default: true)
  end

  def wiki_votes_enabled?
    Setting.enabled?(:wiki_votes_enabled, default: true)
  end
end
