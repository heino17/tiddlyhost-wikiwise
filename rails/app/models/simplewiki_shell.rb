# The SimpleWiki shell bundled with this deployment.
#
# A SimpleWiki site serves a whole HTML shell from its saved content, while its
# pages live in the separate SimpleData island. Offering a newer shell therefore
# means replacing the shell without touching the pages. The newest shell is the
# bundled `simple` empty, refreshed with `make simple-update`.
class SimplewikiShell
  EMPTY_NAME = 'simple'.freeze

  class << self
    # The newest shell version shipped with this deployment, e.g. "0.1.53".
    # The file only changes on deploy, so keep the parsed result per process.
    def latest_version
      @latest_version ||= empty&.tiddlywiki_version
    end

    # The newest shell HTML, ready to be stored as a site's saved content.
    def latest_html
      empty&.html
    end

    # True when `served` sorts before `latest`. Unknown or unparsable versions
    # are never treated as outdated: a custom shell that declares no version
    # must not be replaced by accident.
    def newer?(served, latest = latest_version)
      return false if served.blank? || latest.blank?

      Gem::Version.new(latest) > Gem::Version.new(served)
    rescue ArgumentError
      false
    end

    # Replace the site's shell with the bundled one. Returns the stored shell
    # version, or nil when nothing was changed.
    def upgrade!(site)
      return nil unless site.is_simple?
      return nil unless newer?(site.simplewiki_shell_version)

      preserve_island!(site)
      return nil unless site.content_upload(latest_html)

      latest_version
    end

    private

    def empty
      Empty.find_by_name(EMPTY_NAME)
    end

    # Content normally lives in SimpleData, which the swap leaves alone. A
    # legacy site may still carry its pages only inside the shell island; move
    # them across before the shell is replaced.
    def preserve_island!(site)
      return if site.simple_data.present?

      island = site.th_file.simple_island_content
      data = JSON.parse(island.to_s)
      return unless data.is_a?(Hash) && data['seiten'].present?

      SimpleData.store!(site, island)
    rescue JSON::ParserError
      nil
    end
  end
end
