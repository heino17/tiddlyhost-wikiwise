class SimplewikiController < ApplicationController
  layout false

  before_action :find_site

  # SimpleWiki fetches with a plain fetch() and can't provide the CSRF
  # token, so skip verification for its JSON endpoints.
  skip_before_action :verify_authenticity_token, only: [:status, :data, :shell_update]

  # For CORS preflight and cross-origin reads
  before_action :cors_headers, only: [:status, :data]

  def status
    return head 200 if request.options?
    return head :not_found unless site_exists?

    render json: status_payload
  end

  # Accept the newest SimpleWiki shell bundled with this deployment. The pages
  # live in SimpleData, so only the shell changes. Owner and superuser may
  # decide; collaborators may edit pages but must not replace the shell.
  def shell_update
    return head 200 if request.options?
    return head :not_found unless site_exists? && @site.is_simple?
    return head :forbidden unless user_can_update_shell?
    return head :bad_request unless request.headers['X-Requested-With'] == 'fetch'

    SimplewikiShell.upgrade!(@site)
    @site.reload

    render json: status_payload
  end

  def data
    return head 200 if request.options?
    return head :not_found unless site_exists?

    return render_data if request.get?

    return head :forbidden unless site_saveable?
    return head :bad_request unless request.headers['X-Requested-With'] == 'fetch'

    incoming = request.body.read
    return render plain: 'Empty body', status: :bad_request if incoming.blank?

    unless SimpleData.valid_island_json?(incoming)
      return render plain: 'Invalid SimpleWiki data', status: :unprocessable_entity
    end

    # Conflict detection via If-Match against the current content ETag.
    if_match = request.headers['If-Match']
    if if_match.present? && if_match != '*' && if_match != current_etag
      return render plain: 'Conflict', status: :conflict
    end

    SimpleData.store!(@site, incoming)
    @site.increment_save_count
    if collab_session_active?
      @site.update_columns(
        last_collab_saved_by: session[:collab_name],
        last_collab_saved_at: Time.current
      )
    end

    response.set_header 'ETag', current_etag
    head :no_content
  end

  private

  def render_data
    json = @site.simple_data&.json
    return head :not_found if json.blank?

    response.set_header 'ETag', current_etag
    render plain: json, content_type: 'application/json'
  end

  def status_payload
    {
      kind: 'simple',
      version: @site.tw_version,
      etag: current_etag,
      logged_in: site_saveable?,
      logged_in_as: logged_in_name,
      shell: shell_status,
    }
  end

  def shell_status
    return nil unless @site.is_simple?

    served = @site.simplewiki_shell_version
    latest = @site.simplewiki_shell_latest_version
    {
      served: served,
      latest: latest,
      update_available: SimplewikiShell.newer?(served, latest),
      can_update: user_can_update_shell? && SimplewikiShell.newer?(served, latest),
    }
  end

  def user_can_update_shell?
    return false unless user_signed_in?

    current_user == @site.user || current_user.is_superuser?
  end

  def current_etag
    @site.simple_data&.etag || 'none'
  end

  def logged_in_name
    return current_user.username if user_owns_site?
    return session[:collab_name] if collab_session_active?

    nil
  end

  def site_saveable?
    site_exists? && (user_owns_site? || collab_session_active?)
  end

  def collab_session_active?
    session[:collab_site_id] == @site.id &&
      session[:collab_expires_at].present? &&
      session[:collab_expires_at] > Time.now
  end

  def user_owns_site?
    user_signed_in? && current_user == @site.user
  end

  def site_exists?
    @site.present?
  end

  def find_site
    @site = Site.find_by_name(request.subdomain)
  end

  def cors_headers
    response.set_header 'Access-Control-Allow-Origin', '*'
    response.set_header 'Access-Control-Allow-Methods', 'GET, PUT, OPTIONS'
    response.set_header 'Access-Control-Allow-Headers', 'X-Requested-With, If-Match, Content-Type'
  end
end
