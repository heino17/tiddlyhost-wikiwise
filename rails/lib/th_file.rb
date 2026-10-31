class ThFile < TwFile
  #
  # Note: Some of this is duplicated now in app/models/empty.rb
  # but let's leave it alone for now. It is used (only?) when
  # running `make empty-versions`
  #
  def self.empty_dir
    File.expand_path("#{__dir__}/../tw_content/empties")
  end

  def self.empty_path(empty_type)
    "#{empty_dir}/#{empty_type}.html"
  end

  def self.empty_file_present?(empty_type)
    File.file?(empty_path(empty_type))
  end

  def self.empty_html(empty_type)
    File.read(empty_path(empty_type))
  end

  def self.plugins_dir
    File.expand_path("#{__dir__}/../tw_content/plugins")
  end

  def self.plugin_path(plugin_name)
    "#{plugins_dir}/#{plugin_name}.js.erb"
  end

  def self.plugin_template(plugin_name)
    ERB.new(File.read(plugin_path(plugin_name)))
  end

  def self.from_empty(empty_type)
    from_file(empty_path(empty_type))
  end

  def inject_external_core_url_prefix
    script = external_core_script_tag
    src = script['src']
    script['src'] = "#{Settings.main_site_url}/#{src}" unless src.match?(%r{^https?://})
    self
  end

  # Actually I'm expecting this to be a noop generally since TiddlyWiki
  # uses the local relative src when saving. However it might do something
  # significant if the TiddlyWiki itself had a custom coreURL defined.
  def strip_external_core_url_prefix
    script = external_core_script_tag
    src = script['src']
    script['src'] = File.basename(src)
    self
  end

  # Determine if we think the user could make changes and save.
  # (Used in the `TiddlyHostIsLoggedIn` tiddler for Classic and
  # the `$:/status/IsLoggedIn` tiddler for TW5.)
  def status_is_logged_in(is_logged_in: false, for_download: false)
    if is_logged_in && !for_download
      'yes'
    else
      'no'
    end
  end

  def apply_tw5_mods(site_name, for_download:, local_core:, use_put_saver:, is_logged_in:)
    # rubocop: disable-next Layout/IndentationWidth
    upload_url = if for_download || use_put_saver
      # Clear $:/UploadURL for downloads so the save button in the downloaded
      # file will not try to use upload.js. It should use another save
      # method, probably download to file.
      #
      # Todo: Consider if we should do that also when is_logged_in is nil.
      #
      # Clear $:/UploadURL when using the put saver otherwise TW will
      # prioritize the upload saver
      ''
    else
      # The url for uploads is the same as the site url
      # Todo: Actually using just "/" would work just as well here I think
      Settings.subdomain_site_url(site_name)
    end

    write_tiddlers({
      # TiddlyWiki will POST to this url using code in core/modules/savers/upload.js
      '$:/UploadURL' => upload_url,

      # Set this otherwise TiddlyWiki won't consider upload.js usable unless there
      # is a username and password present.
      # (Not needed for put saver but should be harmless.)
      '$:/UploadWithUrlOnly' => 'yes',

      # Provide a way for TiddlyWikis to detect when they're able to be saved
      '$:/status/IsLoggedIn' => status_is_logged_in(is_logged_in:, for_download:),

      # Used in `$:/core/templates/social-metadata` for social media preview metadata.
      # (It seems like it would be unexpected for these to be set in a downloaded file,
      # so set them to an empty string if we're preparing for a download.)
      # Todo maybe: Allow the user to customize the preview image url, perhaps by creating
      # it as a shadow tiddler
      '$:/SiteUrl' => (for_download ? '' : Settings.subdomain_site_url(site_name)),
      '$:/SiteDomain' => (for_download ? '' : Settings.subdomain_site_host(site_name)),
      '$:/SitePreviewUrl' => (for_download ? '' : Settings.site_thumbnail_url(site_name)),
    })

    # Since every save uploads the entire TiddlyWiki I want to discourage
    # autosave for internal core TiddlyWikis, but let's allow it for external
    # core and see how it goes.
    unless is_external_core?
      write_tiddlers({
        '$:/config/AutoSave' => 'no',
      })
    end

    # Add a prefix to the core js src url for external core TiddlyWikis
    if is_external_core?
      if local_core
        strip_external_core_url_prefix
      else
        inject_external_core_url_prefix
      end
    end
  end

  def apply_classic_mods(site_name, for_download:, is_logged_in:)
    # We don't want to hard code the site url in the plugin, but we also don't
    # want to hard code the domain name and port etc since they're different
    # in different environments. This is clever way to deal with that.
    site_url = Settings.subdomain_site_url("' + siteName + '")

    write_tiddlers({
      'ThostUploadPlugin' => {
        text: plugin_content(:thost_upload_plugin, site_name:, site_url:),
        tags: 'systemConfig',
        modifier: 'TiddlyHost',
      }
    })

    write_shadow_tiddlers({
      # This could be a regular tiddler, but let's make it a shadow tiddler just to be cool.
      # Will be clickable when viewing the plugin since we used 'TiddlyHost' as the modifier above.
      # (I'm using camel case intentionally here despite the usual spelling of Tiddlyhost.)
      'TiddlyHost' => {
        text: "[[Tiddlyhost|#{Settings.main_site_url}]] is a hosting service for ~TiddlyWiki.",
        modifier: 'TiddlyHost',
      },

      # The original idea for this was to read this value in the ThostUploadPlugin to decide
      # whether to show the 'save to tiddlyhost' button, and perhaps to render in read-only
      # mode. However the feedback from classic users is that having the save button unavailable
      # is very disruptive, e.g. if you didn't notice that it was gone and added or modified some
      # content, you're then unable to save the changes. So the default logic in ThostUploadPlugin
      # was changed. This tiddler is still available so it is possible to restore that behavior if
      # you prefer it that way.
      'TiddlyHostIsLoggedIn' => {
        text: status_is_logged_in(is_logged_in:, for_download:),
        modifier: 'TiddlyHost',
      },
    })
  end

  def apply_tiddlyhost_mods(site_name, for_download: false, local_core: false, use_put_saver: false, is_logged_in: false, island_json: nil, display_name: nil, subtitle: nil)
    if is_tw5?
      apply_tw5_mods(site_name, for_download:, local_core:, use_put_saver:, is_logged_in:)
    elsif is_classic?
      apply_classic_mods(site_name, for_download:, is_logged_in:)
    elsif is_simple?
      apply_simple_mods(site_name, for_download:, island_json:, display_name:, subtitle:)
    end
    # No modifications for Feather Wiki or siteleteer
    self
  end

  # SimpleWiki: replace the data island with the stored content and (when
  # serving, not downloading) point the shell at the save endpoints.
  #
  # The island JSON is stored separately from the shell, so the shell
  # attachment itself never needs to change when only the content changes.
  def apply_simple_mods(site_name, for_download: false, island_json: nil, display_name: nil, subtitle: nil)
    island = doc.at_css('script#simplewiki-daten')
    return self unless island

    # Escape "<" so an island value can never break out of the script tag,
    # matching how SimpleWiki itself writes the island.
    island.content = (island_json.presence || island.content.to_s).gsub('<', '\u003c')

    head = doc.at_css('head')
    if head
      remove_simple_title_metas(head)
      add_meta(head, 'simplewiki-title', display_name) if display_name.present?
      add_meta(head, 'simplewiki-subtitle', subtitle) if subtitle.present?
    end

    return self if for_download

    remove_simple_server_metas(head) if head
    if head
      add_meta(head, 'simplewiki-server', 'tiddlyhost')
      add_meta(head, 'simplewiki-status-url', "#{Settings.subdomain_site_url(site_name)}/simplewiki/status")
      add_meta(head, 'simplewiki-data-url', "#{Settings.subdomain_site_url(site_name)}/simplewiki/data")
      add_meta(head, 'simplewiki-shell-update-url', "#{Settings.subdomain_site_url(site_name)}/simplewiki/shell/update")
    end

    self
  end

  def plugin_content(plugin_name, erb_vars)
    ThFile.plugin_template(plugin_name).result_with_hash(erb_vars)
  end

  def add_meta(head, name, content)
    meta = Nokogiri::XML::Node.new('meta', doc)
    meta['name'] = name
    meta['content'] = content
    head.add_child(meta)
  end

  # Replace the shell's title/subtitle metas with the site settings, so a
  # re-serve never accumulates duplicates and a cleared value disappears.
  def remove_simple_title_metas(head)
    %w[simplewiki-title simplewiki-subtitle].each do |name|
      head.xpath("meta[@name='#{name}']").each(&:remove)
    end
  end

  # Remove any previously injected server metas so a re-serve never
  # accumulates duplicates.
  def remove_simple_server_metas(head)
    %w[simplewiki-server simplewiki-status-url simplewiki-data-url simplewiki-shell-update-url].each do |name|
      head.xpath("meta[@name='#{name}']").each(&:remove)
    end
  end

  def get_site_name
    # (It would be nice if there was a better way to do this.)
    if is_tw5?
      tiddler_content('$:/UploadURL').
        match(%r{//([a-z0-9-]+)\.})&.send(:[], 1)
    else
      tiddler_content('ThostUploadPlugin').
        match(/bidix\.initOption\('txtThostSiteName','([a-z0-9-]+)'\);/)&.send(:[], 1)
    end
  end
end
