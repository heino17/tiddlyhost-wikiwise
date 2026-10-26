class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, except: [:index, :new, :create, :view_toggle, :download_all, :check_name]
  before_action :set_sites, only: [:index, :download_all]
  before_action :set_empties_list, only: [:new, :create]
  before_action :set_site_to_clone, only: [:new, :create]

  include SortAndFilterLinkHelper

  include SiteHistory
  include ZipDownloadAll

  def sort_options
    {
      compressed: 'size',
      kind:       'tw_kind',
      name:       'name',
      updated:    'blob_created_at',
      version:    %w[tw_kind tw_version],
      access:     %w[not_searchable is_private],
      views:      'view_count',
      size:       'raw_byte_size',
      origin:     'type,id',
    }
  end

  DEFAULT_SORT = :updated_desc

  def filter_params
    {
      # Fixme maybe: These filters could probably be moved into the db query
      access: {
        hub:    { filter: ->(s) { s.select(&:hub_listed?) }, title: I18n.t('site_filter.access.hub') },
        public: { filter: ->(s) { s.select(&:is_public?).reject(&:hub_listed?) }, title: I18n.t('site_filter.access.public') },
        private: { filter: ->(s) { s.select(&:is_private?) }, title: I18n.t('site_filter.access.private') }
      },
      kind: SiteCommon::KINDS.to_a.to_h { |k, _v| [k.to_sym,
        { filter: ->(ss) { ss.select { |s| s.tw_kind == k.to_s } }, title: I18n.t("site_filter.kind.#{k}") }
      ]},
      # So this gets included in sort_filter_param_keys. The search_text
      # filtering is done separately in set_sites. (Fixme: It's confusing.)
      q: {},
      # Tag filtering - filter is called with (sites, tag_name)
      tags: { filter: ->(sites, tag_name) { sites.select { |s| s.tag_list.include?(tag_name) } } },
    }
  end

  NULL_ALWAYS_LAST = %w[
    version
    size
  ].freeze

  # GET /sites
  # GET /sites.json
  def index
    respond_to do |format|
      format.html do
        @list_mode = current_user.list_mode_pref
        @list_mode_next = current_user.list_mode_pref_next
      end

      format.json do
        @sites = @sites.sort_by(&:id)
      end
    end
  end

  def view_toggle
    current_user.list_mode_pref_cycle
    # Preserve filter and sort params
    redirect_to url_for(params.permit(:controller, :action, :s, :access, :kind, :q, :tags).merge({ action: :index }))
  end

  # Any site that's been saved recently would probably already
  # have a thumbnail. This is to make it easier for users with older
  # sites.
  #
  def create_thumbnail
    @site.update_thumbnail_later unless @site.thumbnail.present?
    redirect_to sites_path
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/1/download
  def download
    local_core = (params[:mode] == 'local_core')
    download_html_content(@site.download_content(local_core:), @site.name)
  end

  def download_core_js
    download_js_content(@site.core_js_content, @site.core_js_name)
  end

  def check_name
    name = params[:name].to_s.strip.downcase
    return render json: { available: false } if name.blank?

    scope = Site.where(name: name)
    site_id = params[:site_id].to_i
    scope = scope.where.not(id: site_id) if site_id.positive?
    render json: { available: !scope.exists? }
  end

  # GET /sites/new
  def new
    @site = Site.new(name: RandomName.generate, empty: Empty.default)
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites
  # POST /sites.json
  def create
    if @site_to_clone
      initial_content = @site_to_clone.file_download
    else
      empty = Empty.find(site_params_for_create[:empty_id])
      initial_content = empty.html
    end

    create_attrs = site_params_for_create.merge(WithSavedContent.attachment_params(initial_content))
    create_attrs.merge!({ cloned_from_id: @site_to_clone.id, empty_id: @site_to_clone.empty_id }) if @site_to_clone

    @site = Site.new(create_attrs)

    respond_to do |format|
      if @site.save
        @site.update_thumbnail_later

        # Only count clones by other users
        if @site_to_clone && @site_to_clone.user != current_user
          @site_to_clone.increment_clone_count
        end

        format.html { redirect_to sites_url, notice: I18n.t('site_view_create_a_site_created_flash') }
        # format.json { render :show, status: :created, location: @site }
      else
        format.html { render :new }
        # format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params_for_update)
        format.html { redirect_to sites_url, notice: I18n.t('site_view_edit_wiki_updated_flash') }
        # format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        # format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /sites/1/upload_form
  def upload_form
    @site = Site.find(params[:id])

    @current_mb = (@site.user&.total_storage_bytes.to_i / 1.megabyte.to_f) || 0

    @max_allowed_mb = if @site.is_tspot?
                        Setting.value_for(:max_account_storage_free_mb, default: 40)
                      elsif @site.user&.subscribed? && @site.user.respond_to?(:premium?) && @site.user.premium?
                        Setting.value_for(:max_account_storage_premium_mb, default: 4000)
                      elsif @site.user&.subscribed?
                        Setting.value_for(:max_account_storage_standard_mb, default: 400)
                      else
                        Setting.value_for(:max_account_storage_free_mb, default: 40)
                      end

    @remaining_mb = [@max_allowed_mb - @current_mb, 0].max

    @max_site_mb = if @site.is_tspot?
                     Setting.value_for(:max_site_size_free_mb, default: 20)
                   elsif @site.user&.subscribed? && @site.user.respond_to?(:premium?) && @site.user.premium?
                     Setting.value_for(:max_site_size_premium_mb, default: 500)
                   elsif @site.user&.subscribed?
                     Setting.value_for(:max_site_size_standard_mb, default: 100)
                   else
                     Setting.value_for(:max_site_size_free_mb, default: 20)
                   end
  end

  def upload
    @site = Site.find(params[:id])

    # Dieselben Variablen wie oben berechnen (für den Fehlerfall)
    @current_mb = (@site.user&.total_storage_bytes.to_i / 1.megabyte.to_f) || 0

    @max_allowed_mb = if @site.is_tspot?
                        Setting.value_for(:max_account_storage_free_mb, default: 40)
                      elsif @site.user&.subscribed? && @site.user.respond_to?(:premium?) && @site.user.premium?
                        Setting.value_for(:max_account_storage_premium_mb, default: 4000)
                      elsif @site.user&.subscribed?
                        Setting.value_for(:max_account_storage_standard_mb, default: 400)
                      else
                        Setting.value_for(:max_account_storage_free_mb, default: 40)
                      end

    @remaining_mb = [@max_allowed_mb - @current_mb, 0].max

    @max_site_mb = if @site.is_tspot?
                     Setting.value_for(:max_site_size_free_mb, default: 20)
                   elsif @site.user&.subscribed? && @site.user.respond_to?(:premium?) && @site.user.premium?
                     Setting.value_for(:max_site_size_premium_mb, default: 500)
                   elsif @site.user&.subscribed?
                     Setting.value_for(:max_site_size_standard_mb, default: 100)
                   else
                     Setting.value_for(:max_site_size_free_mb, default: 20)
                   end

    content = params[:site][:tiddlywiki_file].read
    tw_kind, = TwFile.light_get_kind_and_version(content)
    # Parsing the whole document is only needed for SimpleWiki, where the
    # content island lives inside the shell.
    simplewiki_file = TwFile.new(content) if tw_kind == 'simple'

    if simplewiki_file && !SimpleData.valid_island_json?(simplewiki_file.simple_island_content)
      flash.now[:alert] = t('action_menu_upload_form_invalid_simplewiki')
      render :upload_form, status: :unprocessable_entity
      return
    end

    attrs = WithSavedContent.attachment_params(content, @site)
    attrs.merge!(simplewiki_attrs(simplewiki_file)) if simplewiki_file

    Site.transaction do
      @site.update!(attrs)
      # The shell and the island are stored separately. Serving always uses
      # the stored island, so the uploaded file's content must be taken over
      # here, otherwise an existing (even empty) island would shadow it.
      SimpleData.store!(@site, simplewiki_file.simple_island_content) if simplewiki_file
    end
    redirect_to sites_path, notice: t('action_menu_upload_form_success')
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = @site.errors.full_messages.to_sentence
    render :upload_form, status: :unprocessable_entity
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: I18n.t('site_view_destroy_a_site_destroyed_flash') }
      # format.json { head :no_content }
    end
  end

  def dismiss_collab_banner
    @site = current_user.sites.find(params[:id])
    @site.update_columns(
      last_collab_saved_by: nil,
      last_collab_saved_at: nil
    )
    redirect_to sites_path
  end

  private

  # SimpleWiki keeps its display name and subtitle in meta tags. Import them
  # when the uploaded shell provides them, so the site list and the served
  # title match the file. An empty subtitle clears the site subtitle.
  def simplewiki_attrs(tw_file)
    attrs = {}
    title = tw_file.get_meta('simplewiki-title')
    subtitle = tw_file.get_meta('simplewiki-subtitle')
    attrs[:display_name] = title unless title.nil?
    attrs[:subtitle] = subtitle unless subtitle.nil?
    attrs
  end

  def set_site
    @site = current_user.sites.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sites_url, alert: t("site_view_edit_wiki_site_not_found_flash") and return
  end

  def set_sites
    # Doing some extra work here so that @site_count is correct when user is doing a text
    # search. It's needed because search filtering is done in sql before filter_results,
    # (and I don't feel like changing that).
    @sites = HubQuery.sites_for_user(current_user, sort_by: sort_sql)

    if search_text.present?
      # This is inefficient because we're doing the whole query again, but hopefully it won't matter
      sites_after_search = HubQuery.sites_for_user(current_user, search: search_text, sort_by: sort_sql)
    else
      sites_after_search = @sites
    end
    @filtered_sites = filter_results(sites_after_search)

    @site_count = @sites.count
    @filtered_site_count = @filtered_sites.count

    @total_storage_bytes = current_user.total_storage_bytes
  end

  def set_empties_list
    @empties_for_select = Empty.for_select
  end

  UPDATEABLE_PARAMS = %i[
    name
    display_name
    subtitle
    description
    is_private
    is_searchable
    tag_list
    allow_in_iframe
    prefer_put_saver
    prefer_upload_saver
    allow_public_clone
    skip_etag_check
    disable_download_url
    wiki_collaborators_attributes
  ]

  def site_params_for_update
    params.require(:site).permit(
      *UPDATEABLE_PARAMS,
      wiki_collaborators_attributes: [:id, :name, :password, :enabled, :_destroy]
    )
  end

  UPDATEABLE_PARAMS_ON_CREATE = UPDATEABLE_PARAMS + %i[
    empty_id
  ]

  def site_params_for_create
    params.
      require(:site).
      permit(*UPDATEABLE_PARAMS_ON_CREATE).
      merge(user_id: current_user.id)
  end

  # Sets @site_to_clone which will be nil if there's no clone param or if the
  # site to clone from isn't found. Note you can only clone your own site.
  #
  def set_site_to_clone
    site_to_clone_name = params.permit(:clone)[:clone]
    site_to_clone_maybe = Site.find_by_name(site_to_clone_name) if site_to_clone_name.present?
    @site_to_clone = site_to_clone_maybe if site_to_clone_maybe&.cloneable_by_user?(current_user)
  end
end
