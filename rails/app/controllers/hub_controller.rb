# app/controllers/hub_controller.rb
class HubController < ApplicationController
  # PER_PAGE Konstante entfernt → jetzt dynamisch aus Settings

  before_action :set_show_templates
  before_action :set_kind_filter
  before_action :set_default_title

  # The tests in hub_controller_test don't expect the redirects...
  before_action :redirect_hub_urls unless Rails.env.test?

  def index
    render_hub
  end

  def tag
    @tag = params[:tag]
    render_hub
  end

  def user
    if params[:username].present? && (user = User.find_by_username(params[:username]))
      @user = user
      render_hub
    else
      redirect_to '/explore'
    end
  end

  include SortAndFilterLinkHelper

  def filter_params
    {
      q: {}, # text search
      t: {}, # template filter
      k: {
        tw: { title: I18n.t('site_filter.kind.tw') }
      }.merge(
        SiteCommon::KINDS.to_a.to_h do |k, _v|
          [k.to_sym, { title: I18n.t("site_filter.kind.#{k}") }]
        end
      )
    }
  end

  private

  # Neue Methode: Holt den Wert aus den Admin-Settings
  def per_page
    Setting.value_for(:hub_per_page, default: 18)
  end

  # This query is cached...
  TAGS_CACHE_EXPIRY = Settings.hub_tag_cache_hours.hours
  TAGS_COUNT = Settings.hub_tag_tab_count

  def most_used_tags_cached(show_templates)
    cache_key = "popular_tags_#{show_templates}"
    Rails.cache.fetch(cache_key, expires_in: TAGS_CACHE_EXPIRY) do
      HubQuery.most_used_tags(for_templates: show_templates).first(TAGS_COUNT)
    end
  end

  def render_hub
    @tag_tabs = most_used_tags_cached(@show_templates)
    @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

    # Hier wird jetzt der dynamische Wert verwendet
    @sites = HubQuery.paginated_sites(
      page:          params[:page],
      per_page:      per_page,                    # ← hier kommt der Admin-Wert rein
      sort_by:       sort_opt[:field],
      templates_only: @show_templates,
      kind:          @kind_filter,
      tag:           @tag,
      user:          @user,
      search:        search_text
    )

    render action: :index
  end

  # ... die restlichen Methoden (set_show_templates, set_kind_filter, etc.) bleiben unverändert
  def set_show_templates
    @show_templates = params[:t] == '1'
  end

  def set_kind_filter
    params.delete(:k) unless params[:k].in?(filter_params[:k].keys.map(&:to_s))
    @kind_filter = params[:k]
  end

  def set_default_title
    @thing_name = 'Site'
  end

  def default_sort
    @show_templates ? :cl : :v
  end

  def sort_options
    {
      v:  { title: I18n.t('hub_view_list_sort_view_count'),     field: 'view_count DESC' },
      cl: { title: I18n.t('hub_view_list_sort_clone_count'),     field: 'clone_count DESC' },
      u:  { title: I18n.t('hub_view_list_sort_recently_updated'), field: 'blob_created_at DESC NULLS LAST' },
      c:  { title: I18n.t('hub_view_list_sort_recently_created'), field: 'created_at DESC NULLS LAST' },
      a:  { title: I18n.t('hub_view_list_sort_name_az'),         field: 'name ASC' },
      z:  { title: I18n.t('hub_view_list_sort_name_za'),         field: 'name DESC' },
      nv: { title: I18n.t('hub_view_list_sort_newer_version'),   field: 'tw_version_trimmed DESC NULLS LAST' },
      ov: { title: I18n.t('hub_view_list_sort_older_version'),   field: 'tw_version_trimmed ASC NULLS LAST' },
      r:  { title: I18n.t('hub_view_list_sort_random'),          field: 'rand_sort' },
    }
  end

  HUB_URL_MATCH = %r{^/(?:hub|browse|explore|templates)}

  def redirect_hub_urls
    full_path = request.fullpath
    target_path = (@show_templates ? '/templates' : '/explore')
    redirect_to full_path.sub(HUB_URL_MATCH, target_path) unless full_path.start_with?(target_path)
  end
end