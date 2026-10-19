require 'test_helper'

class SimpleDataTest < ActiveSupport::TestCase
  setup do
    @site = new_site_helper(user: users(:bobby), name: 'simpledata', empty: :simple)
  end

  test 'store! creates the record and a version' do
    SimpleData.store!(@site, '{"seiten":[]}')

    assert_equal '{"seiten":[]}', @site.reload.simple_data.json
    assert_equal 1, @site.simple_data_versions.count
  end

  test 'store! overwrites current but keeps history' do
    SimpleData.store!(@site, '{"seiten":[],"v":1}')
    SimpleData.store!(@site, '{"seiten":[],"v":2}')

    assert_equal '{"seiten":[],"v":2}', @site.reload.simple_data.json
    assert_equal 2, @site.simple_data_versions.count
  end

  test 'etag changes with content and is stable otherwise' do
    a = SimpleData.store!(@site, '{"seiten":[],"v":1}')
    etag1 = a.etag
    a.update!(json: '{"seiten":[],"v":2}')
    refute_equal etag1, a.etag

    a.update!(json: '{"seiten":[],"v":1}')
    assert_equal etag1, a.etag
  end

  test 'prune keeps at most keep count of latest versions' do
    5.times { |i| SimpleData.store!(@site, "{\"seiten\":[],\"v\":#{i}}") }

    keep = @site.keep_count
    assert_equal keep, @site.reload.simple_data_versions.count

    # The newest ones are retained
    latest = @site.simple_data_versions.order(created_at: :desc).first
    assert_equal '{"seiten":[],"v":4}', latest.json
  end
end
