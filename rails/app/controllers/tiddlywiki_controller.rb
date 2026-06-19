class TiddlywikiController < ApplicationController
  layout false

  include SubdomainCommon

  before_action :find_site

  # TiddlyWiki can't provide the token for saving so we need to skip it
  skip_before_action :verify_authenticity_token, only: [:upload_save, :put_save]

  # Rails wants a token for options requests, which TiddlyWiki similarly can't provide
  skip_before_action :verify_authenticity_token,
    only: [:serve, :json_content, :tid_content],
    if: -> { request.options? }

  # For now CORS is supported for only these two requests
  before_action :cors_headers, only: [:json_content, :tid_content]

  def serve
    return site_not_available unless site_visible?

    # ?collaborate → Login-Formular direkt anzeigen (kein Redirect!)
    if params.key?(:collaborate)
      @site_name = @site.name
      return render 'sites/collab_login', layout: 'simple'
    end
  
    # ?collab_logout → Session löschen und Wiki neu laden
    if params.key?(:collab_logout)
      session.delete(:collab_site_id)
      session.delete(:collab_name)
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
      return redirect_to "https://#{request.subdomain}.#{request.domain}/?cache_clean=#{Time.now.to_i}", allow_other_host: true
    end
  
    dummy_webdav_header if request.options? && @site.use_put_saver?
    etag_header
    return head 200 if request.head? || request.options?
    return site_not_valid unless site_valid?
  
    update_view_count_and_access_timestamp
    nginx_no_buffering_header
    content = @site.html_content(is_logged_in: user_owns_site? || collab_session_active?)
    # Banner und Username-Injection nur für TiddlyWiki
    is_tiddlywiki = @site.tw_kind.in?(['tw5', 'tw5x', 'classic'])
  
    if collab_session_active?
      logged_in_text = t('collaborator_logged_in_as')
      collab_name = session[:collab_name]
      log_off_text = t('collaborator_log_off')
    
      is_feather = @site.empty.name == 'feather'
      is_featherx = @site.empty.name == 'featherx'
    
      if is_featherx
        # Featherx Wiki entfernt DOM-Elemente – wir brauchen setInterval
        banner_script = <<~'BANNER'
          <script>
            (function() {
              function insertBanner() {
                if (document.getElementById('collab-banner')) return;
                var b = document.createElement('div');
                b.id = 'collab-banner';
                b.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:#f0a500;color:#000;text-align:center;padding:0px;z-index:99999;font-size:0.777rem;font-family:sans-serif;';
                b.innerHTML = 'LOGGED_IN_TEXT: <strong>COLLAB_NAME</strong> | <form method="GET" action="/" style="display:inline;"><input type="hidden" name="collab_logout" value="1"><button type="submit" style="background:none;border:none;cursor:pointer;color:#000;font-family:sans-serif;font-size:inherit;text-decoration:underline;padding:0;">LOG_OFF_TEXT</button></form>';
                document.body.appendChild(b);
              }
              setTimeout(insertBanner, 1000);
              setInterval(insertBanner, 2000);
            })();
          </script>
        BANNER
        banner_script = banner_script
          .gsub('LOGGED_IN_TEXT', logged_in_text)
          .gsub('COLLAB_NAME', collab_name)
          .gsub('LOG_OFF_TEXT', log_off_text)
        content = content.sub('</body>', "#{banner_script}</body>")
    
      else
        # TiddlyWiki, Classic, Feather etc.
        banner = %(<div id="collab-banner" style="position:fixed;bottom:0;left:0;right:0;background:#f0a500;color:#000;text-align:center;padding:1px;z-index:99999;font-size:0.777rem;font-family:sans-serif;">#{logged_in_text}: <strong>#{collab_name}</strong> | <form method="GET" action="/" style="display:inline;"><input type="hidden" name="collab_logout" value="1"><button type="submit" style="background:none;border:none;cursor:pointer;color:#000;font-family:sans-serif;font-size:inherit;text-decoration:underline;padding:0;">#{log_off_text}</button></form></div>)
        content = content.sub('</body>', "#{banner}</body>")
      end
    end
  
    if collab_session_active? && @site.empty.name == 'sitelet'
      banner_script = %(<script id="collab-banner-script">
      window.addEventListener('load', function() {
        setTimeout(function() {
          if (document.getElementById('collab-banner')) return;
          var b = document.createElement('div');
          b.id = 'collab-banner';
          b.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:#f0a500;color:#000;text-align:center;padding:0px;padding-bottom:10px;z-index:99999;font-size:0.777rem;font-family:sans-serif;';
          b.innerHTML = '#{t('collaborator_logged_in_as')}: <strong>#{session[:collab_name]}</strong> &nbsp;|&nbsp; <form method="GET" action="/" style="display:inline;"><input type="hidden" name="collab_logout" value="1"><button type="submit" style="background:none;border:none;cursor:pointer;color:#000;font-family:sans-serif;font-size:inherit;text-decoration:underline;padding:0;">#{t('collaborator_log_off')}</button></form>';
          document.body.appendChild(b);
        }, 300);
      });
    <\/script>)
    # In <head> injizieren statt </body>!
    content = content.sub('</head>', "#{banner_script}</head>")
    end
  
    # $:/status/UserName setzen
    # $tw.wiki.addTiddler nur für TiddlyWiki!
    if is_tiddlywiki
      username = nil
      username = current_user.username if user_owns_site?
      username = session[:collab_name] if collab_session_active?
    
      if username.present?
        script = %(<script>
          window.addEventListener('load', function() {
            if (window.$tw) {
              $tw.wiki.addTiddler(new $tw.Tiddler({
                title: '$:/status/UserName',
                text: '#{username}'
              }));
            }
          });
        </script>)
        content = content.sub('</body>', "#{script}</body>")
      end
    end
    render html: content.html_safe
  
  end

  def collab_login
    @site_name = @site.name
    render 'sites/collab_login', layout: 'simple'
  end
  
  def collab_login_submit
    name     = params[:name]
    password = params[:password]
  
    collaborator = WikiCollaborator.authenticate_for_site(@site, name, password)
  
    if collaborator
      session[:collab_site_id]   = @site.id
      session[:collab_name]      = collaborator.name
      session[:collab_expires_at] = 24.hours.from_now
      redirect_to "https://#{request.subdomain}.#{request.domain}/", allow_other_host: true
    else
      @site_name = @site.name
      @error = "Name oder Passwort falsch."
      render 'sites/collab_login', layout: 'simple', status: :unprocessable_entity
    end
  end

  def clean_collab_banner(content)
    content
      .gsub(/<div id="collab-banner".*?<\/div>/m, '')
      .gsub(/<script id="collab-banner-script">.*?<\/script>/m, '')
  end

  def json_content
    return site_not_available unless site_visible?

    etag_header

    # Return empty body for options request with CORS headers
    return head 200 if request.options?

    include_system = params[:include_system] == '1'
    skinny = params[:skinny] == '1'
    title = params[:title]
    pretty = params[:pretty] == '1'

    json_data = @site.json_data(include_system:, skinny:)

    json_data = json_data.select { |d| Array.wrap(title).include?(d['title']) } if title.present?

    # I guess...
    update_view_count_and_access_timestamp

    render json: pretty ? JSON.pretty_generate(json_data) : json_data.to_json
  end

  def tid_content
    return site_not_available unless site_visible?

    title = params[:title]
    tiddler_data = @site.tiddler_data(title)

    # If we get nil, assume the tiddler doesn't exist
    return head 404 unless tiddler_data

    etag_header

    # Return empty body for options request with CORS headers
    return head 200 if request.options?

    # Otherwise render it in .tid format
    render plain: tiddler_data_to_tid_text(tiddler_data)
  end

  def favicon
    # It probably doesn't matter much about the favicon, but
    # let's make its availability the same as the site
    return site_not_available unless site_visible?

    send_favicon(@site.favicon_asset_name)
  end

  def thumb_png
    return site_not_available unless site_visible? && @site.thumbnail.present?

    send_data @site.thumbnail.download, type: 'image/png', disposition: 'inline'
  end

  def download
    return site_not_available unless site_downloadable?

    # Downloads count as a view
    update_view_count_and_access_timestamp

    nginx_no_buffering_header
    download_html_content(@site.download_content, @site.name)
  end

  # Using the "upload" saver
  def upload_save
    begin
      if site_saveable?
        userfile = params[:userfile]
        cleaned = clean_collab_banner(userfile.read)
        @site.file_upload(StringIO.new(cleaned))
        @site.increment_save_count
        if collab_session_active?
          @site.update_columns(
            last_collab_saved_by: session[:collab_name],
            last_collab_saved_at: Time.current
          )
        end
        render plain: "0 - OK\n"
      else
        # Give a 200 status no matter what so the user sees the message in a browser alert
        render plain: I18n.t('admin.tab_settings.settings_save_failed', main_site_url: main_site_url)
      end
    rescue StandardError => e
      # Todo: Should probably give a generic "Save failed!" message, and log the real problem
      render plain: "#{e.class.name} - #{e.message}\n"
    end
  end

  # Using the "put" saver
  def put_save
    begin
      if site_saveable?
        if site_save_would_overwrite?
          err_message = 'It appears that the site has been updated since you first ' \
            'loaded it. Saving now would cause those updates to be overwritten.' \
            "\n\n" \
            'Try doing a shift+reload to ensure you have the latest changes, then ' \
            "reapply your edits. (If that doesn't work for some reason, there is an " \
            'option you can set in the Tiddlyhost advanced site settings to ignore ' \
            'this error and save anyway.)'
          render status: 412, plain: err_message
        else
          # Banner bereinigen und speichern
          body = clean_collab_banner(request.body.read)
          @site.file_upload(StringIO.new(body))
          @site.increment_save_count
          if collab_session_active?
            @site.update_columns(
              last_collab_saved_by: session[:collab_name],
              last_collab_saved_at: Time.current
            )
          end
          head 204
        end
      else
        err_message = I18n.t('admin.tab_settings.settings_save_failed', main_site_url: main_site_url)
        render status: 403, plain: err_message
      end
    rescue StandardError => e
      err_message = "#{e.class.name} #{e.message}"
      render status: 500, plain: err_message
    end
  end

  private

  def update_view_count_and_access_timestamp
    # Don't count admin clicks on other users' sites
    return if user_is_admin? && !user_owns_site?

    # Don't count views by site owner
    @site.increment_view_count unless user_owns_site?

    # Do count accesses by owner (or anyone else)
    @site.increment_access_count

    # Always touch the timestamp
    @site.touch_accessed_at
  end

  def site_not_valid
    @status_code, @status_message = [418, 'Invalid TiddlyWiki']
    render :site_not_available, status: @status_code, layout: 'simple'
  end

  def site_not_available
    @status_code, @status_message = site_not_available_status

    # Send an empty body if it's probably not going to be visible
    return head @status_code if action_name != 'serve' || request.head? || request.options? || !request.format.html?

    # Otherwise send the "not available" page
    render :site_not_available, status: @status_code, layout: 'simple'
  end

  def site_not_available_status
    # Site doesn't exist
    return [404, 'Not Found'] unless site_exists?

    # Special handling for the /download url
    return [404, 'Not Found'] if action_name == 'download' && site_visible? && site_download_url_disabled?

    # User signed in, site unavailable
    return [403, 'Forbidden'] if user_signed_in?

    # User not signed in, site unavailable
    [401, 'Unauthorized']
  end

  def site_visible?
    site_exists? && (site_public? || user_owns_site? || user_is_admin?)
  end

  def site_downloadable?
    site_visible? && !site_download_url_disabled?
  end

  def site_saveable?
    site_exists? && (user_owns_site? || collab_session_active?)
  end

  def collab_session_active?
    session[:collab_site_id] == @site.id &&
      session[:collab_expires_at].present? &&
      session[:collab_expires_at] > Time.now
  end

  def site_save_would_overwrite?
    return false if @site.skip_etag_check?

    expected_etag = request.headers['If-Match']
    expected_etag.present? && expected_etag != @site.tw_etag
  end

  def user_owns_site?
    user_signed_in? && current_user == @site.user
  end

  def site_exists?
    @site.present?
  end

  def site_public?
    @site.is_public?
  end

  def site_valid?
    # Beware this requires downloading the site's content
    @site.looks_valid?
  end

  def site_download_url_disabled?
    @site.disable_download_url?
  end

  def find_site
    site_name = request.subdomain
    @site = Site.find_by_name(site_name)
  end

  def tiddler_data_to_tid_text(tiddler_data)
    [
      tiddler_data.except('text').sort_by { |k, _| k }.map { |k, v| "#{k}: #{v}\n" },
      "\n",
      tiddler_data['text'],
      "\n",
    ].join
  end

  # So browsers are permitted to do fetches from different domains
  def cors_headers
    response.set_header 'Access-Control-Allow-Origin', '*'
    response.set_header 'Access-Control-Request-Method', 'GET'
    response.set_header 'Access-Control-Allow-Headers', 'X-Requested-With'
  end

  # TiddlyWiki just checks if the header exists so the value doesn't matter
  def dummy_webdav_header
    response.set_header 'dav', "Dummy WebDAV header to enable TiddlyWiki's PUT saver"
  end
end