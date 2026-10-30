require 'test_helper'

class SiteSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:mysite)
    host! @site.host
  end

  test 'login on a site host leads to the Devise sign-in page' do
    get '/login'

    assert_redirected_to '/users/sign_in'
  end

  test 'login while already signed in returns to the wiki' do
    sign_in users(:bobby)

    get '/login'

    assert_redirected_to '/'
  end

  test 'signing in on a site host returns a superuser to the wiki' do
    user = confirmed_user(user_type: UserType.superuser)

    post '/users/sign_in', params: { user: { email: user.email, password: 'Abcd1234' } }

    assert_redirected_to '/'
  end

  test 'signing in on the main site still sends a superuser to the admin area' do
    host! Settings.url_defaults[:host]
    user = confirmed_user(user_type: UserType.superuser)

    post '/users/sign_in', params: { user: { email: user.email, password: 'Abcd1234' } }

    assert_redirected_to '/admin'
  end

  private

  def confirmed_user(user_type:)
    user = User.new(
      email: "login-#{SecureRandom.hex(4)}@example.com",
      name: 'Site Login',
      username: "login-#{SecureRandom.hex(4)}",
      password: 'Abcd1234',
      user_type: user_type
    )
    # Already confirmed, so creating the user sends no confirmation mail.
    user.skip_confirmation!
    user.save!
    user
  end
end
