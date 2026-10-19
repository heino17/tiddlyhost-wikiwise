require 'test_helper'

class SimplewikiControllerTest < ActionDispatch::IntegrationTest
  ISLAND = { version: 1, seiten: [], startseite: '', sprache: 'de', thema: 'light' }.freeze

  setup do
    @user = users(:bobby)
    @site = new_site_helper(user: @user, name: 'simplesite', empty: :simple)
    host! @site.host
  end

  test 'status reports kind and version' do
    get '/simplewiki/status'
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 'simple', body['kind']
    assert_equal @site.tw_version, body['version']
    assert_equal 'none', body['etag']
    refute body['logged_in']
    assert_nil body['logged_in_as']
  end

  test 'data GET returns 404 when no island stored yet' do
    get '/simplewiki/data'
    assert_response :not_found
  end

  test 'data PUT requires auth' do
    sign_in users(:mary)
    put '/simplewiki/data',
      params: { seiten: [], extra: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :forbidden
  end

  test 'data PUT requires fetch header' do
    sign_in @user
    put '/simplewiki/data',
      params: { seiten: [] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    assert_response :bad_request
  end

  test 'data PUT rejects invalid json' do
    sign_in @user
    put '/simplewiki/data',
      params: 'not json',
      headers: { 'Content-Type' => 'text/plain', 'X-Requested-With' => 'fetch' }
    assert_response :unprocessable_entity
  end

  test 'owner can save and read back the island' do
    sign_in @user

    put '/simplewiki/data',
      params: ISLAND.merge(seiten: [{ titel: 'Start' }]).to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :no_content
    etag = response.headers['ETag']
    assert etag.present?

    get '/simplewiki/data'
    assert_response :success
    assert_equal etag, response.headers['ETag']
    body = JSON.parse(response.body)
    assert_equal [{ 'titel' => 'Start' }], body['seiten']
  end

  test 'data PUT with stale If-Match returns 409' do
    sign_in @user
    put '/simplewiki/data',
      params: ISLAND.to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :no_content

    put '/simplewiki/data',
      params: ISLAND.merge(sprache: 'en').to_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-Requested-With' => 'fetch',
        'If-Match' => 'bogusetag',
      }
    assert_response :conflict
  end

  test 'data PUT with matching If-Match succeeds' do
    sign_in @user
    put '/simplewiki/data',
      params: ISLAND.to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :no_content
    etag = response.headers['ETag']

    put '/simplewiki/data',
      params: ISLAND.merge(sprache: 'en').to_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-Requested-With' => 'fetch',
        'If-Match' => etag,
      }
    assert_response :no_content
  end

  test 'each save keeps a version history bounded by keep_count' do
    sign_in @user
    3.times do |i|
      put '/simplewiki/data',
        params: ISLAND.merge(sprache: "lang#{i}").to_json,
        headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
      assert_response :no_content
    end

    assert_equal 3, @site.simple_data_versions.count
  end

  test 'serving injects server metas and the stored island' do
    sign_in @user
    put '/simplewiki/data',
      params: ISLAND.merge(sprache: 'en').to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :no_content

    get '/'
    assert_response :success

    th_file = ThFile.new(response.body)
    assert th_file.is_simple?
    assert_equal 'tiddlyhost', th_file.get_meta('simplewiki-server')
    assert_nil th_file.get_meta('simplewiki-version')
    assert_match %r{/simplewiki/status\z}, th_file.get_meta('simplewiki-status-url')
    assert_match %r{/simplewiki/data\z}, th_file.get_meta('simplewiki-data-url')

    island = th_file.simple_island_content
    assert_equal 'en', JSON.parse(island)['sprache']
  end

  test 'download has no server metas' do
    sign_in @user
    get '/download'
    assert_response :success

    th_file = ThFile.new(response.body)
    assert_nil th_file.get_meta('simplewiki-server')
    assert_nil th_file.get_meta('simplewiki-status-url')
  end
end
