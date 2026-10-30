require 'test_helper'

class SimplewikiControllerTest < ActionDispatch::IntegrationTest
  ISLAND = { version: 1, seiten: [], startseite: '', sprache: 'de', thema: 'light' }.freeze
  OLD_SHELL_VERSION = '0.1.51'.freeze
  OLD_SHELL_PATH = Rails.root.join('tw_content/empties/simple/0.1.51.html')

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
    assert_equal @site.tw_version, body.dig('shell', 'served')
    assert_equal SimplewikiShell.latest_version, body.dig('shell', 'latest')
    refute body.dig('shell', 'update_available')
    refute body.dig('shell', 'can_update')
  end

  test 'status reports an available shell update without granting it anonymously' do
    old_site = old_simple_site(name: 'oldsimple')
    host! old_site.host

    get '/simplewiki/status'
    assert_response :success

    shell = JSON.parse(response.body)['shell']
    assert_equal OLD_SHELL_VERSION, shell['served']
    assert_equal SimplewikiShell.latest_version, shell['latest']
    assert shell['update_available']
    refute shell['can_update']
  end

  test 'owner sees that the shell can be updated' do
    old_site = old_simple_site(name: 'ownersimple')
    host! old_site.host
    sign_in @user

    get '/simplewiki/status'
    assert_response :success

    shell = JSON.parse(response.body)['shell']
    assert shell['update_available']
    assert shell['can_update']
  end

  test 'shell update requires the fetch header' do
    old_site = old_simple_site(name: 'headerless')
    host! old_site.host
    sign_in @user

    put '/simplewiki/shell/update'
    assert_response :bad_request
    assert_equal OLD_SHELL_VERSION, old_site.reload.tw_version
  end

  test 'a signed-in non-owner cannot update the shell' do
    old_site = old_simple_site(name: 'maryssimple', user: users(:mary))
    host! old_site.host
    sign_in @user

    put '/simplewiki/shell/update', headers: { 'X-Requested-With' => 'fetch' }
    assert_response :forbidden
    assert_equal OLD_SHELL_VERSION, old_site.reload.tw_version
  end

  test 'shell update is not found for a non-simple site' do
    tw5_site = new_site_helper(user: @user, name: 'tw5site', empty: :tw5)
    host! tw5_site.host
    sign_in @user

    put '/simplewiki/shell/update', headers: { 'X-Requested-With' => 'fetch' }
    assert_response :not_found
  end

  test 'owner can update the shell and the pages stay' do
    old_site = old_simple_site(name: 'updatable')
    host! old_site.host
    sign_in @user

    put '/simplewiki/data',
      params: ISLAND.merge(seiten: [{ titel: 'Bleibt' }]).to_json,
      headers: { 'Content-Type' => 'application/json', 'X-Requested-With' => 'fetch' }
    assert_response :no_content
    etag = response.headers['ETag']

    put '/simplewiki/shell/update', headers: { 'X-Requested-With' => 'fetch' }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal SimplewikiShell.latest_version, body.dig('shell', 'served')
    refute body.dig('shell', 'update_available')
    assert_equal SimplewikiShell.latest_version, old_site.reload.tw_version
    assert_equal etag, old_site.simple_data.etag
    assert_equal 'Bleibt', JSON.parse(old_site.simple_data.json)['seiten'].first['titel']
  end

  test 'superuser may update a shell they do not own' do
    old_site = old_simple_site(name: 'supervised', user: users(:mary))
    host! old_site.host
    sign_in @user
    @user.update!(user_type: UserType.superuser)

    put '/simplewiki/shell/update', headers: { 'X-Requested-With' => 'fetch' }
    assert_response :success
    assert_equal SimplewikiShell.latest_version, old_site.reload.tw_version
  end

  test 'shell update keeps an island that only lives in the old shell' do
    legacy_island = ISLAND.merge(seiten: [{ titel: 'Alt' }])
    old_site = old_simple_site(name: 'legacyisland')
    shell_with_island = old_site.th_file.
      apply_simple_mods(old_site.name, island_json: legacy_island.to_json).to_html
    old_site.content_upload(shell_with_island)
    assert_nil old_site.reload.simple_data

    host! old_site.host
    sign_in @user
    put '/simplewiki/shell/update', headers: { 'X-Requested-With' => 'fetch' }

    assert_response :success
    assert_equal SimplewikiShell.latest_version, old_site.reload.tw_version
    assert_equal 'Alt', JSON.parse(old_site.simple_data.json)['seiten'].first['titel']
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

  private

  def old_simple_site(name:, user: @user)
    new_site_helper(user: user, name: name, empty: :simple,
      empty_content: File.read(OLD_SHELL_PATH))
  end
end
