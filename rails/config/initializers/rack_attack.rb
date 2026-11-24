# Login rate limiting.
#
# Two independent limits apply to POST /users/sign_in when the admin setting
# `login_rate_limit_enabled` is on:
#
#   * every login attempt from one IP address
#   * failed login attempts for one email/username
#
# Rack::Attack runs before Rails, so the email counter is fed by a Warden hook
# that fires only on real authentication failures. Successful sign-ins clear it.
if defined?(Rack::Attack)
  class Rack::Attack
    LOGIN_PATH = '/users/sign_in'.freeze

    class << self
      def login_attempt?(request)
        request.post? && request.path == LOGIN_PATH
      end

      def login_identifier(request)
        value = request.params.dig('user', 'email') ||
          request.params.dig('user', 'username')

        value.to_s.strip.downcase.presence
      end

      def rate_limit_period
        Settings::Features.login_rate_limit_period_minutes.to_i.clamp(1, 1440).minutes
      end

      def ip_attempt_limit
        Settings::Features.login_rate_limit_ip_attempts.to_i.clamp(1, 1000)
      end

      def email_failure_limit
        Settings::Features.login_rate_limit_email_failures.to_i.clamp(1, 1000)
      end

      # Rails.cache is a NullStore in test and in dev unless caching is
      # explicitly enabled. Rack::Attack needs a real store to count anything.
      def ensure_counter_store!
        self.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
      end

      def increment_counter(key, period)
        store = self.cache.store
        options = { expires_in: period.to_i }

        # ActiveSupport stores disagree on whether options are keywords
        # (MemoryStore) or a positional Hash (MemCacheStore).
        value = begin
          store.increment(key, 1, **options)
        rescue ArgumentError
          store.increment(key, 1, options)
        end

        value.to_i
      rescue StandardError => e
        Rails.logger.warn("Login rate limit counter failed: #{e.message}")
        0
      end

      def failure_key(identifier)
        "login/email-failures:#{identifier}"
      end

      def record_login_failure(identifier)
        return if identifier.blank? || !Settings::Features.login_rate_limit_enabled?

        increment_counter(failure_key(identifier), rate_limit_period)
      end

      def clear_login_failures(identifier)
        return if identifier.blank?

        self.cache.store.delete(failure_key(identifier))
      rescue StandardError => e
        Rails.logger.warn("Could not clear login failure counter: #{e.message}")
      end

      def too_many_failures?(identifier)
        return false if identifier.blank?

        self.cache.store.read(failure_key(identifier)).to_i >= email_failure_limit
      rescue StandardError => e
        Rails.logger.warn("Could not read login failure counter: #{e.message}")
        false
      end
    end

    ensure_counter_store!

    # Counts successful and failed login attempts alike. The 4th attempt with
    # the default limit of 3 is rejected before it reaches Devise.
    blocklist('login/ip') do |request|
      next false unless Settings::Features.login_rate_limit_enabled?
      next false unless Rack::Attack.login_attempt?(request)

      key = "login/ip:#{request.ip}"
      Rack::Attack.increment_counter(key, Rack::Attack.rate_limit_period) > Rack::Attack.ip_attempt_limit
    end

    # The counter for this one is incremented by the Warden failure hook below.
    blocklist('login/email') do |request|
      next false unless Settings::Features.login_rate_limit_enabled?
      next false unless Rack::Attack.login_attempt?(request)

      Rack::Attack.too_many_failures?(Rack::Attack.login_identifier(request))
    end

    self.blocklisted_responder = lambda do |_request|
      message = I18n.t(
        'login_rate_limit_exceeded',
        default: 'Too many login attempts. Please try again in a few minutes.'
      )
      period = Settings::Features.login_rate_limit_period_minutes.to_i

      body = <<~HTML
        <!doctype html>
        <html lang="#{I18n.locale}">
          <head><title>#{ERB::Util.html_escape(message)}</title></head>
          <body>
            <h1>#{ERB::Util.html_escape(message)}</h1>
            <p><a href="#{Rack::Utils.escape_html(LOGIN_PATH)}">#{ERB::Util.html_escape(I18n.t('log_in_page_heading', default: 'Log in'))}</a></p>
          </body>
        </html>
      HTML

      [429, {
        'Content-Type' => 'text/html; charset=utf-8',
        'Retry-After' => period.to_s,
      }, [body]]
    end
  end

  if defined?(Warden::Manager)
    Warden::Manager.before_failure do |env, options|
      # Warden rewrites PATH_INFO to /unauthenticated before running this hook,
      # so use the attempted_path it stored for us.
      attempted_path = options[:attempted_path].to_s.split('?').first
      next unless attempted_path == Rack::Attack::LOGIN_PATH

      request = Rack::Request.new(env)
      Rack::Attack.record_login_failure(Rack::Attack.login_identifier(request))
    end

    Warden::Manager.after_authentication do |_user, auth, options|
      next if options[:scope] && options[:scope] != :user

      request = Rack::Request.new(auth.env)
      next unless Rack::Attack.login_attempt?(request)

      Rack::Attack.clear_login_failures(Rack::Attack.login_identifier(request))
    end
  end
end
