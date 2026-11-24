require 'test_helper'

class LoginRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    Setting.set_enabled(:login_rate_limit_enabled, true)
    Setting.set_value(:login_rate_limit_period_minutes, 5)

    hex = SecureRandom.hex(4)
    @user = User.new(
      email: "rate-limit-#{hex}@example.com",
      name: 'Rate Limit User',
      username: "rate-limit-#{hex}",
      password: 'Abcd1234'
    )
    @user.skip_confirmation!
    @user.save!
  end

  test 'the fourth login attempt from one IP is blocked' do
    Setting.set_value(:login_rate_limit_ip_attempts, 3)
    Setting.set_value(:login_rate_limit_email_failures, 100)

    3.times { |index| attempt_login(email: "other-#{index}@example.com") }

    assert_response :success

    attempt_login(email: 'yet-another@example.com')

    assert_response :too_many_requests
    assert_match I18n.t('login_rate_limit_exceeded'), response.body
  end

  test 'an account is blocked after three failed attempts' do
    Setting.set_value(:login_rate_limit_ip_attempts, 100)
    Setting.set_value(:login_rate_limit_email_failures, 3)

    3.times { attempt_login(email: @user.email) }

    assert_response :success

    attempt_login(email: @user.email, password: 'Abcd1234')

    assert_response :too_many_requests
  end

  test 'a successful sign in clears the failure counter' do
    Setting.set_value(:login_rate_limit_ip_attempts, 100)
    Setting.set_value(:login_rate_limit_email_failures, 3)

    2.times { attempt_login(email: @user.email) }
    attempt_login(email: @user.email, password: 'Abcd1234')

    assert_redirected_to '/'

    delete '/users/sign_out'

    2.times { attempt_login(email: @user.email) }

    assert_response :success
    assert_no_match I18n.t('login_rate_limit_exceeded'), response.body
  end

  test 'disabling rate limiting allows repeated attempts' do
    Setting.set_enabled(:login_rate_limit_enabled, false)
    Setting.set_value(:login_rate_limit_ip_attempts, 1)
    Setting.set_value(:login_rate_limit_email_failures, 1)

    5.times { attempt_login(email: @user.email) }

    assert_response :success
    assert_no_match I18n.t('login_rate_limit_exceeded'), response.body
  end

  private

  def attempt_login(email:, password: 'wrong')
    post '/users/sign_in', params: {
      user: { email: email, password: password },
      login_puzzle: login_puzzle_params,
    }
  end
end
