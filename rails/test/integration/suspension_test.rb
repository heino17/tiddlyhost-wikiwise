require 'test_helper'

class SuspensionTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:mary)
    @admin.update!(user_type: UserType.superuser)
    @user = users(:bobby)
    @site = sites(:mysite)
  end

  test 'admin can suspend and unsuspend a single wiki' do
    sign_in @admin

    patch admin_suspend_site_path(@site)

    assert_redirected_to admin_sites_path
    assert @site.reload.suspended?
    assert_not_nil @site.suspended_at
    assert_not @site.available?

    patch admin_unsuspend_site_path(@site)

    assert_not @site.reload.suspended?
    assert_nil @site.suspended_at
    assert @site.available?
  end

  test 'admin can delete a wiki' do
    sign_in @admin

    assert_difference 'Site.count', -1 do
      delete admin_destroy_site_path(@site)
    end

    assert_redirected_to admin_sites_path
  end

  test 'suspended wiki is not served and disappears from the hub' do
    assert_includes Site.for_hub, @site

    @site.update!(suspended: true)

    assert_not_includes Site.for_hub, @site

    host! @site.host
    get '/'

    assert_response :unauthorized
  end

  test 'suspending a user hides the wikis without changing them' do
    sign_in @admin

    patch admin_suspend_user_path(@user)

    assert_redirected_to admin_user_path(@user)
    assert @user.reload.suspended?
    assert_not_nil @user.suspended_at
    assert_not @site.reload.suspended?, 'the site records should stay untouched'
    assert_not @site.available?
    assert_not_includes Site.for_hub, @site

    patch admin_unsuspend_user_path(@user)

    assert_not @user.reload.suspended?
    assert @site.reload.available?
    assert_includes Site.for_hub, @site
  end

  test 'suspended user cannot sign in' do
    @user.update!(password: 'Abcd1234', suspended: true)

    post '/users/sign_in', params: {
      user: { email: @user.email, password: 'Abcd1234' },
      login_puzzle: login_puzzle_params
    }

    assert_redirected_to new_user_session_path

    follow_redirect!

    assert_response :success
    assert_includes response.body, I18n.t('devise.failure.suspended')
  end

  test 'suspending a user drops the current session' do
    sign_in @user
    get sites_path
    assert_response :success

    @user.update!(suspended: true)

    get sites_path

    assert_redirected_to new_user_session_path
  end

  test 'suspended user gets no password reset mail' do
    @user.update!(suspended: true)
    ActionMailer::Base.deliveries.clear

    User.send_reset_password_instructions('email' => @user.email)

    assert_empty ActionMailer::Base.deliveries
  end

  test 'admin cannot suspend their own account' do
    sign_in @admin

    patch admin_suspend_user_path(@admin)

    assert_redirected_to admin_user_path(@admin)
    assert_not @admin.reload.suspended?
  end

  test 'suspension filters work on both admin pages' do
    sign_in @admin
    @user.update!(suspended: true)
    @site.update!(suspended: true)

    get '/admin/sites', params: { site_suspended: '1' }
    assert_response :success
    get '/admin/sites', params: { site_suspended: '0' }
    assert_response :success
    get '/admin/users', params: { user_suspended: '1' }
    assert_response :success
    get '/admin/users', params: { user_suspended: '0' }
    assert_response :success
  end

  test 'admin pages render the suspension controls' do
    sign_in @admin

    get '/admin/sites'
    assert_response :success
    assert_select "form[action='#{admin_suspend_site_path(@site)}']"
    assert_select "form[action='#{admin_destroy_site_path(@site)}']"

    get admin_user_path(@user)
    assert_response :success
    assert_select "form[action='#{admin_suspend_user_path(@user)}']"

    @user.update!(suspended: true)

    get admin_user_path(@user)
    assert_response :success
    assert_select "form[action='#{admin_unsuspend_user_path(@user)}']"
  end

  test 'non-admin cannot suspend a wiki' do
    sign_in @user

    patch admin_suspend_site_path(@site)

    assert_response :not_found
    assert_not @site.reload.suspended?
  end
end
