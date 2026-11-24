class SessionsController < Devise::SessionsController
  LOGIN_PUZZLE_LIFETIME = 10.minutes

  prepend_before_action :verify_login_puzzle, only: :create
  before_action :configure_sign_in_params, only: [:create]
  before_action :prepare_login_puzzle, only: [:new, :create]

  # Used by the puzzle's refresh button to get a new board and token.
  def puzzle
    render json: login_puzzle_json(prepare_login_puzzle)
  end

  private

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:redir_to_site])
  end

  def prepare_login_puzzle
    @login_puzzle = build_login_puzzle
    session[:login_puzzle] = {
      'token' => @login_puzzle[:token],
      'answer' => @login_puzzle[:answer],
      'expires_at' => @login_puzzle[:expires_at],
    }
    @login_puzzle
  end

  def build_login_puzzle
    tiles = LoginPuzzle.generate

    {
      token: SecureRandom.hex(16),
      tiles: tiles,
      answer: LoginPuzzle.answer_for(tiles),
      expires_at: LOGIN_PUZZLE_LIFETIME.from_now.to_i,
    }
  end

  def login_puzzle_json(puzzle)
    {
      token: puzzle[:token],
      tiles: puzzle[:tiles].map { |tile| tile.slice(:id, :emoji, :animal) },
    }
  end

  # MWS gates the submit button in the browser. We do the same here and also
  # check the solution on the server, so a direct POST cannot skip the puzzle.
  def verify_login_puzzle
    return if user_signed_in?

    stored = session[:login_puzzle]
    submitted = params[:login_puzzle] || {}
    answer = submitted[:answer].to_s.split(',').map(&:strip).reject(&:blank?).sort

    valid = stored.present? &&
      stored['token'].to_s.present? &&
      stored['token'].to_s == submitted[:token].to_s &&
      stored['expires_at'].to_i > Time.current.to_i &&
      answer == stored['answer']

    return if valid

    session.delete(:login_puzzle)
    redirect_to new_user_session_path, alert: I18n.t('login_puzzle_error')
  end

  def after_sign_in_path_for(resource)
    session.delete(:login_puzzle)

    # A site host's root is the wiki itself. Without this, a superuser
    # signing in there would be sent to /admin, which only exists on the
    # main site and would be a 404 on the subdomain.
    return root_path if request.subdomain.present? && request.subdomain != 'www'

    # 1. Admin-Weiterleitung
    if resource.is_superuser?
      return admin_path
    end

    # 2. Deine bestehende private-site-Weiterleitung
    if request.post? && params[:user] &&
       (@site_redir = params[:user][:site_redir]) &&
       (@site = Site.find_by_name(@site_redir)) &&
       @site.user == current_user
      return @site.url
    end

    # 3. Standard-Devise-Weiterleitung
    super
  end
end
