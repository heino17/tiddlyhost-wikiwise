class Site < ApplicationRecord
  include SiteCommon

  # Comment & Voting
  has_many :comments, dependent: :destroy
  has_many :site_votes, dependent: :destroy

  # Für die Anzeige: Durchschnitt (für Sterne) oder Summe (für +1/-1)
  def vote_score
    return 0 if site_votes.empty?

    # Für Sterne: site_votes.average(:value).round(1)  # z. B. 4.2
    # Für +1/-1: site_votes.sum(:value)  # z. B. +12
    site_votes.average(:value).round(1) # Starte mit Sterne-Version
  end

  def vote_count
    site_votes.count
  end

  def update_vote_score
    return if destroyed?
    new_score = site_votes.average(:value)&.round(1) || 0.0
    update_column(:vote_score, new_score)
  end
  # Einfacher, robuster Callback:
  after_commit :update_vote_score, on: [:create, :update, :destroy]
  # Comment & Voting end

  # The empty used when the site was created.
  # (It might not reflect what the site is now since the
  # user may have uploaded a different type of TiddlyWiki.)
  belongs_to :empty

  # Will be set if the site was created as a clone of another site
  # (Beware the original site might have been deleted, so the association
  # could return nil even if the id field is present.)
  belongs_to :cloned_from, optional: true, class_name: :Site

  # The timestamps can be a few milliseconds apart, so that's why we need the interval
  # Todo: blob_created_at would be a more useful timestamp to use here than updated_at.
  scope :never_updated,         -> { where("AGE(sites.updated_at, sites.created_at) <= INTERVAL '0.5 SECOND'") }
  scope :updated_at_least_once, -> { where("AGE(sites.updated_at, sites.created_at) >  INTERVAL '0.5 SECOND'") }

  scope :for_hub, -> { searchable.updated_at_least_once }

  scope :templates_only, -> { where(is_private: false, allow_public_clone: true) }

  # For compatibility with tspot sites
  scope :not_deleted, -> { all }

  validates :name,
    presence: true,
    uniqueness: true,
    length: {
      # Let's reserve sites with one or two letter names
      minimum: 3,
      # RFC1035 says 63 is the maximum size of a subdomain...
      maximum: 63,
    },
    format: {
      # Must be only lowercase letters, numerals, and dashes
      # Must not have more than one consecutive dash
      # Must not start or end with a dash
      # (See also app/javascript/packs/application.js)
      without: / [^a-z0-9-] | -- | ^- | -$ /x,
      message: "'%<value>s' is not allowed. Please choose a different site name.",
    },
    exclusion: {
      # Let's reserve a few common subdomains
      in: %w[
        www
        ftp
        pop
        imap
        smtp
        mail
        help
        faq
        support
        wiki
      ],
      message: "'%<value>s' is reserved. Please choose a different site name.",
    }

  def th_file
    @_th_file ||= ThFile.new(file_download)
  end

  def th_file_for_blob_id(blob_id)
    ThFile.new(file_download(blob_id))
  end

  def looks_valid?
    th_file.looks_valid?
  end

  def html_content(is_logged_in: false)
    th_file.apply_tiddlyhost_mods(name,
      is_logged_in:, use_put_saver: use_put_saver?).to_html
  end

  def html_content_for_blob_id(blob_id, is_logged_in: false)
    th_file_for_blob_id(blob_id).apply_tiddlyhost_mods(name,
      # Note: There might be some tricky edge cases around the value of use_put_saver?
      # here since it's based on the current site, not the specific version being fetched
      is_logged_in:, use_put_saver: use_put_saver?).to_html
  end

  def json_data(opts = {})
    th_file.tiddlers_data(**opts)
  end

  def tiddler_data(tiddler_name)
    blob_cache(:tiddler_data, tiddler_name) do
      th_file.tiddler_data(tiddler_name)
    end
  end

  def download_content(local_core: false)
    th_file.apply_tiddlyhost_mods(name, for_download: true, local_core:).to_html
  end

  def download_content_for_blob_id(blob_id)
    # Todo maybe: Consider the local core option here
    ThFile.new(file_download(blob_id)).apply_tiddlyhost_mods(name, for_download: true).to_html
  end

  # Could be more clever here and try to read it from the script src,
  # but let's keep it simple to begin with.
  def core_js_name
    "tiddlywikicore-#{tw_version}.js"
  end

  def core_js_content
    File.read("#{Rails.root}/public/#{core_js_name}")
  end

  def use_put_saver?
    # These always use put saver
    return true if is_feather? || is_sitelet?

    # Classic always uses upload saver
    return false if is_classic?

    # Use any user specified preferences from the site's advanced options
    return false if prefer_upload_saver?
    return true if prefer_put_saver?

    # Otherwise use whatever the default is based on the version
    default_to_put_saver?
  end

  def cloneable_by_user?(some_user)
    # You can always clone your own site
    return true if some_user && some_user == self.user

    # You can clone a publicly cloneable site
    is_public? && allow_public_clone?
  end

  def cloneable_by_public?
    cloneable_by_user?(nil)
  end

  # Any TiddlyWiki5 should work with the put saver, but there are some error
  # message improvements in 5.2.3 that provide a marginally better UX when the
  # save fails, so let's use the put saver by default from that version onwards
  # and stick with the legacy upload saver for earler versions
  DEFAULT_TO_PUT_SAVER_FROM_VERSION = '5.2.3'

  def default_to_put_saver?
    # Use Gem::Version here to handle the comparison properly, e.g. so "5.10" > "5.9"
    Gem::Version.new(tw_version) >= Gem::Version.new(DEFAULT_TO_PUT_SAVER_FROM_VERSION)
  end

  # True if any non-default advanced settings are present
  def has_advanced_settings?
    return true if is_tw5? && use_put_saver? != default_to_put_saver?
    return true if allow_public_clone?
    return true if allow_in_iframe?
    return true if skip_etag_check?
    return true if disable_download_url?

    false
  end

  def url
    Settings.subdomain_site_url(name)
  end

  def host
    Settings.subdomain_site_host(name)
  end

  def favicon_asset_name
    'favicon-green.ico'
  end

  def is_tspot?
    false
  end

  def deleted?
    false
  end

  def redirect_to
    nil
  end

  # If site history is enabled then keep many saves, otherwise keep just
  # a few. Users won't be able to see them (for now at least), but would
  # be nice if the save history is not entirely empty after subscribing.
  # See also app/jobs/prune_attachments_job.
  # Wie viele Versionen eines Wikis sollen behalten werden?
  
  # === keep_count (Versions-History) ===
  def keep_count
    if is_tspot?
      Setting.value_for(:keep_count_tiddlyspot, default: 4)
    elsif user&.subscribed? && user.respond_to?(:premium?) && user.premium?
      Setting.value_for(:keep_count_premium, default: 17)
    elsif user&.subscribed?
      Setting.value_for(:keep_count_standard, default: 8)
    else
      Setting.value_for(:keep_count_free, default: 4)
    end
  end

  def keep_count_for_tiddlyspot
    Setting.value_for(:keep_count_tiddlyspot, default: 4)
  end

  validates :tag_list, 
    length: {
      maximum: -> { Setting.value_for(:max_tags_per_site, default: 7) },
      message: ->(record, data) {
        I18n.t(
          "admin.max_tags_per_site.too_many",
          count: Setting.value_for(:max_tags_per_site, default: 7)
        )
      }
    }

  # Optional: Automatisches Kürzen auf die erlaubte Anzahl (netter UX)
  # before_validation :limit_tags

  # Für Speichergrößen-Limits
  validate :site_size_within_limit
    validate :account_storage_within_limit

  private

  def site_history_enabled?
    Settings.feature_enabled?(:site_history, user)
  end

  # def limit_tags
  #   max = Setting.value_for(:max_tags_per_site, default: 7)
  #   self.tag_list = tag_list.first(max) if tag_list.size > max
  # end

  # === Pro-Wiki Größenlimit ===
  def site_size_within_limit  
    return if user&.is_admin?
  
    return unless saved_content_files.attached? && user.present?

    max_allowed_mb = if is_tspot?
                       Setting.value_for(:max_site_size_free_mb, default: 20)
                     elsif user.subscribed? && user.respond_to?(:premium?) && user.premium?
                       Setting.value_for(:max_site_size_premium_mb, default: 100)
                     elsif user.subscribed?
                       Setting.value_for(:max_site_size_standard_mb, default: 20)
                     else
                       Setting.value_for(:max_site_size_free_mb, default: 20)
                     end

    current_size_mb = (raw_byte_size || 0) / 1.megabyte.to_f

    if current_size_mb > max_allowed_mb
            errors.add(:base, I18n.t("action_menu_upload_form_site_size_exceeded",
                               limit: max_allowed_mb,
                               current: current_size_mb.round(1)))
    end
  end

  # === Account-weites Gesamtlimit ===
  def account_storage_within_limit
    return if user&.is_admin? || user.nil?
    return unless saved_content_files.attached? && raw_byte_size.present?

    new_size_mb      = raw_byte_size / 1.megabyte.to_f

    # Alte Größe dieses Wikis abziehen (falls es sich um ein Update handelt)
    old_size_mb = raw_byte_size_was.to_i / 1.megabyte.to_f

    previous_total_mb = user.total_storage_bytes / 1.megabyte.to_f
    effective_total_mb = previous_total_mb - old_size_mb + new_size_mb

    max_allowed_mb = if is_tspot?
                       Setting.value_for(:max_account_storage_free_mb, default: 40)
                     elsif user.subscribed? && user.respond_to?(:premium?) && user.premium?
                       Setting.value_for(:max_account_storage_premium_mb, default: 4000)
                     elsif user.subscribed?
                       Setting.value_for(:max_account_storage_standard_mb, default: 400)
                     else
                       Setting.value_for(:max_account_storage_free_mb, default: 40)
                     end

    if effective_total_mb > max_allowed_mb
      errors.add(:base, I18n.t("action_menu_upload_form_account_storage_exceeded",
                               limit:   max_allowed_mb,
                               current: previous_total_mb.round(1),
                               new:     new_size_mb.round(1)))
    end
  end
end
