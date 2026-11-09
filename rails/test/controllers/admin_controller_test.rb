require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:mary)
    @admin.update(user_type: UserType.superuser)
  end

  test 'unauthorized user' do
    %w[
      /admin
      /admin/users

    ].each do |page|
      sign_in users(:bobby)
      get page
      assert_response :not_found
      assert_select 'h1', '404 Not Found', @response.body
    end
  end

  test 'smoke test' do
    sign_in @admin
    %w[
      /admin
      /admin/charts
      /admin/users
      /admin/sites
      /admin/tspot_sites
      /admin/storage
      /admin/settings
      /admin/etc

    ].each do |page|
      get page
      assert_response :success
    end
  end

  test 'history retention settings are available' do
    sign_in @admin
    get '/admin/settings'
    assert_response :success

    assert_includes response.body, I18n.t('admin.history_daily_keep_days.label')
    assert_includes response.body, I18n.t('admin.history_session_gap_minutes.label')
    assert_includes response.body, I18n.t('admin.history_session_keep_count.label')
  end

  test 'site thumbnails open a preview modal' do
    site = sites(:mysite)
    site.thumbnail.attach(io: StringIO.new('thumbnail'), filename: 'thumb.png', content_type: 'image/png')

    sign_in @admin
    get '/admin/sites'

    assert_response :success
    assert_select 'div[data-controller="thumbnail-preview"]' do
      assert_select 'button.thumbnail-preview-trigger[data-action="thumbnail-preview#open"] > svg', count: 1

      assert_select 'button.thumbnail-preview-trigger' do |buttons|
        button = buttons.first
        assert_equal 'mysite', button['data-thumbnail-title']
        assert_equal I18n.t('site_view_thumbnail_preview_alt', name: 'mysite'), button['data-thumbnail-alt']
        assert_includes button['data-thumbnail-url'], '/rails/active_storage/'
      end

      assert_select '#thumbnail-preview-modal img.thumbnail-preview-image'
    end
  end

  test 'search sites' do
    sign_in @admin
    # The q param is a text search
    get '/admin/sites', params: { q: "text" }
    assert_response :success
  end

  test 'search users' do
    sign_in @admin
    # The q param is a text search
    get '/admin/users', params: { q: "text" }
    assert_response :success
  end
end
