require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get '/'
    assert_response :success
    assert_select '.jumbotron h3', 'Get started now'
    assert_select '.navbar-brand img[src*="simplewiki-icon"]'
    assert_select 'link[href*="favicon"]'
  end

  test 'favicon is an ico file' do
    get '/favicon.ico'
    assert_response :success
    assert_equal 'image/vnd.microsoft.icon', response.media_type
    assert response.body.start_with?("\x00\x00\x01\x00".b)
  end

  test 'www subdomain should redirect' do
    host! "www.#{Settings.main_site_host}"
    get '/'
    assert_redirected_to Settings.url_defaults
  end

  # See also test/integration/sites_test.rb
end
