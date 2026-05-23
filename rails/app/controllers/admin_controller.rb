require 'csv'

class AdminController < ApplicationController
  before_action :require_admin_user!
  include AdminChartData

  before_action :authenticate_user!
  before_action :require_admin_user!

  before_action :enable_chart_js, only: [:charts]

  before_action :require_admin
  def require_admin
    unless current_user&.is_admin?
      redirect_to root_path, alert: "Nicht erlaubt."
    end
  end

  def index
    @title = 'Stats'

    @view_count = Site.sum(:access_count)
    @tspot_view_count = TspotSite.sum(:access_count)
    @total_site_bytes = ActiveStorage::Blob.sum(:byte_size)

    @user_count = User.count
    @subscription_count = User.with_subscriptions_active.count
    @alt_subscription_count = User.where('alt_subscription IS NOT NULL').
      where.not(id: Settings.secrets(:my_account_ids) || []).count

    @never_signed_in_users = User.signed_in_never.count
    @signed_in_once_users = User.signed_in_once.count

    active_users = User.signed_in_more_than_once
    @active_daily = active_users.active_day.count
    @active_weekly = active_users.active_week.count
    @active_monthly = active_users.active_month.count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

    @tspot_site_count = TspotSite.no_stubs.count
    @owned_tspot_site_count = TspotSite.owned.count
    @saved_tspot_count = TspotSite.where.not(save_count: 0).count

    @jobs_count = Delayed::Job.count

    @jobs_running_count = Delayed::Job.where.not(locked_by: nil).count
    @jobs_running_since = Delayed::Job.where.not(locked_by: nil).first&.locked_at
    @jobs_running_sites = GenerateThumbnailJob.running_sites
    @jobs_alert = @jobs_running_since && @jobs_running_since < 10.minutes.ago
  end

  include SortAndFilterLinkHelper

  NULL_ALWAYS_LAST = %w[
    username
    description
    owner
    version
    kind
    clone
    subscr
  ].freeze

  def users
    render_records User.left_joins(:sites, :tspot_sites).join_subscriptions.group(:id)
  end

  def sites
    render_records Site.left_joins(:user, :empty).with_blobs_for_query.group(:id)
  end

  def tspot_sites
    render_records TspotSite.left_joins(:user).with_blobs_for_query.group(:id)
  end

  def settings
    load_settings
  end

  def update_settings
    load_settings

    # --- 1. Alle Locale-Keys sammeln ---
    locale_keys = available_locales.keys.map { |loc| "locale_enabled_#{loc}" }

    # --- 2. PrÃ¼fen: Wird die aktuelle Sprache deaktiviert? ---
    current_locale_key = "locale_enabled_#{I18n.locale}"
    if params[:settings][current_locale_key] == "0"
      flash[:alert] = I18n.t('admin.locales_hint_messages.cannot_disable_current_locale')
      flash.keep(:alert)
      return redirect_to admin_settings_path(active_tab: "locales")
    end

    # --- 3. PrÃ¼fen: Wird die Default-Sprache deaktiviert? ---
    default_locale = Setting.string_for(:default_locale, default: "en").to_sym
    default_locale_key = "locale_enabled_#{default_locale}"

    if params[:settings][default_locale_key] == "0"
      return redirect_to admin_settings_path(active_tab: "locales"),
            alert: {
              message: t("admin.locales_hint_messages.cannot_disable_default_locale"),
              auto_dismiss: false
            }

    end

    # --- 4. PrÃ¼fen: Werden ALLE Sprachen deaktiviert? ---
    disabled_count = locale_keys.count { |k| params[:settings][k] == "0" }

    if disabled_count == locale_keys.size
      flash[:alert] = I18n.t('admin.locales_hint_messages.cannot_disable_all_locales')
      flash.keep(:alert)
      return redirect_to admin_settings_path(active_tab: "locales")
    end

    # --- 5. Alles OK â†’ speichern ---
    params[:settings]&.each do |key_str, val|
      if key_str == "default_locale"
        Setting.set_string(:default_locale, val)
        next
      end

      key_sym = key_str.to_sym
      config = settings_config.find { |s| s[:key] == key_sym }

      if config
        case config[:type]
        when :boolean
          Setting.set_enabled(key_sym, val == "1")
        when :integer, :select, :text, :string
          Setting.set_value(key_sym, val.to_s.strip)
        end
      else
        Rails.logger.warn "Unknown setting skipped: #{key_sym}"
      end
    end

    active_tab = params[:active_tab].presence || 'general'

    redirect_to admin_settings_path(active_tab: active_tab),
                notice: t("admin.tab_settings.settings_saved")
  rescue => e
    flash.now[:alert] = "Fehler beim Speichern: #{e.message}"
    load_settings
    render :settings, status: :unprocessable_entity
  end

  def etc
  end

  def raw_download
    klass = params[:type] == 'TspotSite' ? TspotSite : Site
    site = klass.find(params[:id])
    blob_id = params[:blob_id]

    raw_html = site.file_download(blob_id)
    download_filename = "raw_#{klass.name.underscore}_#{site.id}_#{blob_id}_#{site.name}"
    download_html_content(raw_html, download_filename)
  end

  def boom
    raise 'Boom!'
  end

  def pool_stats
    render json: ActiveRecord::Base.connection.pool.stat.to_json
  end

  def charts
    @chart_data = chart_data(params[:chart])
  end

  def storage
    if params[:dry_run].present?
      @dry_run_results = run_dry_run
    end
    @dry_run_done = params[:dry_run].present?

    # ActiveStorage Stats
    @blob_count       = ActiveStorage::Blob.count
    @attachment_count = ActiveStorage::Attachment.count
    @total_blob_bytes = ActiveStorage::Blob.sum(:byte_size)
  
    # Orphaned Blobs
    @orphaned_blobs = ActiveStorage::Blob.left_outer_joins(:attachments)
                                         .where(active_storage_attachments: { id: nil })
    @orphaned_blob_count = @orphaned_blobs.count
  
    # Storage Folder Stats
    storage_path = Rails.root.join("storage")
    @storage_files = Dir.glob("#{storage_path}/**/*").select { |f| File.file?(f) }
    @storage_total_bytes = @storage_files.sum { |f| File.size(f) }
  
    # Orphaned Files
    used_keys = ActiveStorage::Blob.pluck(:key)
    @orphaned_files = @storage_files.reject { |f| used_keys.any? { |key| f.include?(key) } }
    @orphaned_files_count = @orphaned_files.count
    @orphaned_files_bytes = @orphaned_files.sum { |f| File.size(f) }
  
    # Largest Blobs
    @largest_blobs = ActiveStorage::Blob.order(byte_size: :desc).limit(10)
  
    @largest_wikis = Site.order(raw_byte_size: :desc).limit(10)
  
    # Speicherverbrauch pro User
    @user_storage = User.all.map do |user|
      # Wiki-Speicher
      wiki_bytes = Site.where(user_id: user.id).sum(:raw_byte_size)
    
      # ActiveStorage-Speicher (z.B. Thumbnails)
      blob_ids = ActiveStorage::Attachment
        .where(record_type: "Site", record_id: Site.where(user_id: user.id).pluck(:id))
        .pluck(:blob_id)
    
      active_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
    
      {
        user: user,
        wiki_bytes: wiki_bytes,
        active_bytes: active_bytes,
        total_bytes: wiki_bytes + active_bytes
      }
    end
    
    # Sortieren nach Gesamtverbrauch
    @user_storage.sort_by! { |row| -row[:total_bytes] }
    
    # Anzeige Gesamtverbrauch
    @total_user_storage_bytes = @user_storage.sum { |row| row[:total_bytes] }
  
    # Sortierung für User-Speicher
    sort = params[:sort] || "total_desc"
    
    @user_storage = User.all.map do |user|
      wiki_bytes = Site.where(user_id: user.id).sum(:raw_byte_size)
    
      blob_ids = ActiveStorage::Attachment
        .where(record_type: "Site", record_id: Site.where(user_id: user.id).pluck(:id))
        .pluck(:blob_id)
    
      active_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
    
      {
        user: user,
        wiki_bytes: wiki_bytes,
        active_bytes: active_bytes,
        total_bytes: wiki_bytes + active_bytes,
        wiki_count: Site.where(user_id: user.id).count
      }
    end
    
    @user_storage = case sort
    when "user_asc"      then @user_storage.sort_by { |r| r[:user].username }
    when "user_desc"     then @user_storage.sort_by { |r| r[:user].username }.reverse
    when "wiki_asc"      then @user_storage.sort_by { |r| r[:wiki_count] }
    when "wiki_desc"     then @user_storage.sort_by { |r| r[:wiki_count] }.reverse
    when "wiki_bytes_asc"  then @user_storage.sort_by { |r| r[:wiki_bytes] }
    when "wiki_bytes_desc" then @user_storage.sort_by { |r| r[:wiki_bytes] }.reverse
    when "active_bytes_asc"  then @user_storage.sort_by { |r| r[:active_bytes] }
    when "active_bytes_desc" then @user_storage.sort_by { |r| r[:active_bytes] }.reverse
    when "size_asc"      then @user_storage.sort_by { |r| r[:total_bytes] }
    else                      @user_storage.sort_by { |r| r[:total_bytes] }.reverse # size_desc
    end
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def storage_cleanup
    # Delete orphaned blobs
    ActiveStorage::Blob.left_outer_joins(:attachments)
                       .where(active_storage_attachments: { id: nil })
                       .find_each(&:purge)
  
    # Delete orphaned files
    storage_path = Rails.root.join("storage")
    all_files = Dir.glob("#{storage_path}/**/*").select { |f| File.file?(f) }
    used_keys = ActiveStorage::Blob.pluck(:key)
    orphaned_files = all_files.reject { |f| used_keys.any? { |key| f.include?(key) } }
    orphaned_files.each { |file| File.delete(file) }
  
    redirect_to admin_storage_path, notice: "🧹 " + t('admin.storage_flash_cleanup_success')
  end

  def sort_options
    {
      accesses:     'access_count',
      clone:        'cloned_from_id',
      clones:       'clone_count',
      created:      'created_at',
      confirmed:    'confirmed_at',
      createdip:    'created_ip',
      currentsignin:'current_sign_in_at',
      description:  "NULLIF(sites.description, '')",
      email:        'email',
      #empty:       'empties.name',   # auskommentiert lassen
      av:           ['use_gravatar', 'use_libravatar'],
      id:           'id',
      iframes:      'allow_in_iframe',
      kind:         'tw_kind',
      lastaccess:   'accessed_at',
      lastsignin:   'last_sign_in_at',
      lastupdate:   'updated_at',
      logins:       'sign_in_count',
      name:         'name',
      owner:        'COALESCE(users.username, users.email)',
      type:         'user_type_id',
      subscr:       ['MAX(pay_subscriptions.status)', 'MAX(pay_subscriptions.id)'],
      private:      'is_private',
      put:          'prefer_put_saver',
      saves:        'save_count',
      hub:          'is_searchable',
      raw:          'raw_byte_size',
      sites:        'COUNT(sites.id)',
      storage:      'storage_service',
      template:     'allow_public_clone',
      tspotsites:   'COUNT(tspot_sites.id)',
      upload:       'prefer_upload_saver',
      username:     "NULLIF(username, '')",
      version:      'tw_version',
      versions:     'COUNT(active_storage_blobs.id)',
      views:        'view_count',
    }
  end

  def filter_params
    {
      owned: {
        '1' => { title: I18n.t('admin.radio_filter.owned.yes'),     filter: ->(r) { r.where.not(user_id: nil) } },
        '0' => { title: I18n.t('admin.radio_filter.owned.no'),      filter: ->(r) { r.where(user_id: nil) } },
      },
      saved: {
        '1' => { title: I18n.t('admin.radio_filter.saved.yes'),      filter: ->(r) { r.where.not(save_count: 0) } },
        '0' => { title: I18n.t('admin.radio_filter.saved.no'),       filter: ->(r) { r.where(save_count: 0) } },
      },
      private: {
        '1' => { title: I18n.t('admin.radio_filter.private_yes'),    filter: ->(r) { r.where.not(is_private: false) } },
        '0' => { title: I18n.t('admin.radio_filter.private_no'),     filter: ->(r) { r.where(is_private: false) } },
      },
      hub: {
        '1' => { title: I18n.t('admin.radio_filter.hub_yes'),        filter: ->(r) { r.where.not(is_searchable: false) } },
        '0' => { title: I18n.t('admin.radio_filter.hub_no'),         filter: ->(r) { r.where(is_searchable: false) } },
      },
      template: {
        '1' => { title: I18n.t('admin.radio_filter.template_yes'),   filter: ->(r) { r.where.not(allow_public_clone: false) } },
        '0' => { title: I18n.t('admin.radio_filter.template_no'),    filter: ->(r) { r.where(allow_public_clone: false) } },
      },
      no_stub: {
        '1' => { title: I18n.t('admin.radio_filter.no_stub.yes'),    filter: lambda(&:no_stubs) },
        '0' => { title: I18n.t('admin.radio_filter.no_stub.no'),     filter: lambda(&:stubs) },
      },
      new_pass: {
        '1' => { title: I18n.t('admin.radio_filter.new_pass.yes'),   filter: ->(r) { r.where.not(password_digest: nil) } },
        '0' => { title: I18n.t('admin.radio_filter.new_pass.no'),    filter: ->(r) { r.where(password_digest: nil) } },
      },
      deleted: {
        '1' => { title: I18n.t('admin.radio_filter.deleted.yes'),    filter: ->(r) { r.where.not(deleted: false) } },
        '0' => { title: I18n.t('admin.radio_filter.deleted.no'),     filter: ->(r) { r.where(deleted: false) } },
      },
      kind: {
        filter: ->(r, kind) { r.where(tw_kind: kind) },
        # Hier kein title, weil es dynamisch pro Kind ist (oder du fÃ¼gst einen Gruppen-Titel hinzu)
      },
      user: {
        # See filter_by_user_maybe below
      },
      q: {
        filter: ->(r, search) { r.admin_search_for(search) },
      },
      signedin: {
        '1' => { title: I18n.t('admin.radio_filter.signedin_yes'),   filter: ->(r) { r.where('sign_in_count > 0') } },
        '0' => { title: I18n.t('admin.radio_filter.signedin_no'),    filter: ->(r) { r.where('sign_in_count = 0') } },
      },
      subscription: {
        '2' => { title: I18n.t('admin.radio_filter.subscription.current'), filter: ->(r) { r.where("pay_subscriptions.status = 'active' OR NOT alt_subscription IS NULL") } },
        '1' => { title: I18n.t('admin.radio_filter.subscription.any'),     filter: ->(r) { r.where.not('pay_subscriptions.id IS NULL') } },
        '0' => { title: I18n.t('admin.radio_filter.subscription.none'),    filter: ->(r) { r.where('pay_subscriptions.id IS NULL and alt_subscription IS NULL') } },
      },
    }
  end

  private

  def run_dry_run
    orphaned_blobs = ActiveStorage::Blob.left_outer_joins(:attachments)
                                        .where(active_storage_attachments: { id: nil })
  
    orphaned_files = find_orphaned_files
  
    {
      blobs: orphaned_blobs.map { |b| "#{b.id} – #{b.filename} – #{b.byte_size} bytes" },
      files: orphaned_files
    }
  end
  
  def find_orphaned_files
    storage_path = Rails.root.join("storage")
    all_files = Dir.glob("#{storage_path}/**/*").select { |f| File.file?(f) }
    used_keys = ActiveStorage::Blob.pluck(:key)
    all_files.reject { |f| used_keys.any? { |key| f.include?(key) } }
  end

  def default_sort
    case action_name
    when 'tspot_sites'
      :lastupdate_desc
    else
      :created_desc
    end
  end

  def render_records(records)
    @title = action_name.titleize
    @records = records

    # Filtering
    filter_by_user_maybe
    @records = filter_results(@records)

    # Sorting
    @records = @records.order(Arel.sql(sort_sql))

    # Pagination
    @records = @records.paginate(page: params[:page], per_page: 15)

    render action: :paginated_records
  end

  def filter_by_user_maybe
    @user = params[:user].present? && User.find_by_id(params[:user])
    if @user
      case action_name
      when 'users'
        @records = @records.where(id: @user.id)
        @title = "#{@user.username_or_email}'s Details"
      else
        @records = @records.where(user: @user)
        @title = "#{@user.username_or_email}'s #{@title}"
      end
    end
  end

  def enable_chart_js
    @need_chart_js = true
  end

  def settings_config
    [
      # === Allgemein ===
      { key: :startpage_introduction_block_enabled, group: 'general', default: true,  type: :boolean },
      { key: :special_imprint_enabled,              group: 'general', default: true,  type: :boolean },
      { key: :cookie_consent_enabled,               group: 'general', default: false, type: :boolean },
      { key: :registration_enabled,                 group: 'general', default: false, type: :boolean },
  
      # === Community ===
      { key: :comments_enabled,   group: 'community', default: true,  type: :boolean },
      { key: :wiki_votes_enabled, group: 'community', default: true,  type: :boolean },
      { key: :shoutbox_enabled,   group: 'community', default: true,  type: :boolean },
  
      # === Hub & Darstellung ===
      { key: :default_theme_mode,  group: 'hub', default: 'light',  type: :select, options: ['light', 'dark', 'auto'] },
      { key: :sticky_menu_enabled, group: 'hub', default:  true,  type: :boolean },
      { key: :default_theme_width, group: 'hub', default: '1169px',  type: :string },
      { key: :hub_per_page,        group: 'hub',       default: 17,    type: :integer, min: 1, max: 51 },
      # === Banner Message ===
      { key: :banner_message_enabled,    group: 'hub', default: true, type: :boolean },
      { key: :banner_message_sticky,     group: 'hub', default: true, type: :boolean },
      { key: :banner_message_visibility, group: 'hub', default: 'all',  type: :select, options: ['all', 'logged_in', 'logged_out'] },
      { key: :banner_message_html,       group: 'hub', default: "",     type: :text },
  
      # === Abonnements ===
      { key: :subscriptions_enabled, group: 'subscription', default: true, type: :boolean },
      { key: :avatars_enabled,       group: 'subscription', default: false, type: :boolean },
      { key: :max_tags_per_site,     group: 'subscription', default: 17,     type: :integer, min: 0, max: 17 },
  
      # === Speicher & Versionen ===
      { key: :keep_count_free,       group: 'storage', default: 4,   type: :integer, min: 1, max: 100 },
      { key: :keep_count_standard,   group: 'storage', default: 8, type: :integer, min: 1, max: 100 },
      { key: :keep_count_premium,    group: 'storage', default: 17, type: :integer, min: 1, max: 100 },
      { key: :keep_count_tiddlyspot, group: 'storage', default: 4,   type: :integer, min: 1, max: 100 },
    
      # === Site-Größen-Limits pro Plan
      { key: :max_site_size_free_mb,     group: 'storage',   default: 20,  type: :integer, min: 0, max: 200 },
      { key: :max_site_size_standard_mb, group: 'storage',   default: 100, type: :integer, min: 0, max: 1000 },
      { key: :max_site_size_premium_mb,  group: 'storage',   default: 500,type: :integer, min: 0, max: 5000 },
    
      # Account-weites Speicherlimit (Gesamtgröße aller Wikis eines Users)
      { key: :max_account_storage_free_mb,      group: 'storage', default: 40,  type: :integer, min: 1, max: 10000 },
      { key: :max_account_storage_standard_mb,  group: 'storage', default: 400, type: :integer, min: 1, max: 10000 },
      { key: :max_account_storage_premium_mb,   group: 'storage', default: 4000, type: :integer, min: 1, max: 10000 },
    
      # === Sprachen (dynamisch erzeugt) ===
      { key: :default_locale, group: 'locales', default: :en, type: :string, label: "Standardsprache", description: "Sprache, die als Standard verwendet wird" },

      *available_locales.map { |locale, name|
        {
          key:        "locale_enabled_#{locale}".to_sym,
          group:      'locales',
          default:    true,
          type:       :boolean,
          label:      "#{name} aktivieren",
          description: "Sprache #{name} in der gesamten Anwendung verfügbar machen"
        }
      }
    ]
  end
  
  def load_settings
    config = settings_config.dup   # dup damit wir das Original nicht verändern

    # Filter: Standard- und Premium-Einstellungen ausblenden, wenn Abos deaktiviert sind
    unless Setting.enabled?(:subscriptions_enabled)
      config.reject! do |cfg|
        key = cfg[:key].to_s
        key.include?("_standard") || key.include?("_premium")
      end
    end
  
    @settings = config.map do |cfg|
      if cfg[:type] == :boolean
        current_value = Setting.enabled?(cfg[:key], default: cfg[:default])
      else
        current_value = Setting.value_for(cfg[:key], default: cfg[:default])
      end
  
      {
        key:           cfg[:key],
        group:         cfg[:group],
        options:       cfg[:options],
        label:         t("admin.#{cfg[:key]}.label"),
        description:   t("admin.#{cfg[:key]}.description"),
        default:       cfg[:default],
        type:          cfg[:type],
        min:           cfg[:min],
        max:           cfg[:max],
        current_value: current_value,
        raw_value:   Setting.find_by(key: cfg[:key])&.value.presence || cfg[:default].to_s
      }
    end
  end

  def comments_list
    @comments = Comment.order(created_at: :desc)
  end
end
