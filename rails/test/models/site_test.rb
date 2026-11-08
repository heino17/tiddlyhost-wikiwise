require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @site = Site.find_by_name('mysite')
  end

  test 'url' do
    assert_equal 'mysite.tiddlyhost-test-example.com', @site.host
    assert_equal 'http://mysite.tiddlyhost-test-example.com', @site.url
    assert_equal 'http://tiddlyhost-test-example.com', Settings.main_site_url
  end

  test 'name validation' do
    # These names are invalid
    [
      '-aaa',
      'aaa-',
      '-aaa-',
      'a--a',
      'Aaa',
      'aa',
      'abc$',
      'x' * 64,
      'ftp',
      'www',
      'wiki',
      "foo\nbar",
      "foo\tbar",
      'foo bar',
    ].each do |invalid_name|
      @site.update(name: invalid_name)
      refute @site.valid?, "#{invalid_name} unexpectedly allowed!"
    end

    # These names are valid
    [
      'aaa',
      'aa-aa',
      'bbb-cc-dd',
      'x' * 63,
      'ab9',
      '777',
      '123-aaa',
      'myftp',
      'shit', # Hmm...
    ].each do |valid_name|
      @site.update(name: valid_name)
      assert @site.valid?, "#{valid_name} unexpectedly disallowed!"
    end
  end

  test 'view counts and timestamps' do
    orig_updated_at = @site.updated_at.to_i
    orig_accessed_at = @site.accessed_at.to_i
    orig_view_count = @site.view_count
    orig_access_count = @site.access_count

    @site.touch_accessed_at
    # The accessed_at field is touched
    assert_operator orig_accessed_at, :<, @site.accessed_at.to_i
    # The updated_at field is not
    assert_equal orig_updated_at, @site.updated_at.to_i

    @site.increment_view_count
    @site.increment_access_count
    # The counters were incremented
    assert_equal orig_view_count + 1, @site.reload.view_count
    assert_equal orig_access_count + 1, @site.reload.access_count
    # The updated_at field is untouched
    assert_equal orig_updated_at, @site.updated_at.to_i
  end

  test 'when to use put saver' do
    {
      true => [
        { tw_kind: 'feather' },
        { tw_kind: 'tw5', tw_version: '5.2.3' },
        { tw_kind: 'tw5', tw_version: '5.2.2', prefer_put_saver: true },

        # Unlikely edge case showing preference is ignored
        { tw_kind: 'feather', prefer_upload_saver: true },
      ],

      false => [
        { tw_kind: 'classic' },
        { tw_kind: 'tw5', tw_version: '5.2.2' },
        { tw_kind: 'tw5', tw_version: '5.2.3', prefer_upload_saver: true },

        # Edge case to demonstrate that prefer upload takes precendent if both are set
        { tw_kind: 'tw5', tw_version: '5.2.2', prefer_put_saver: true, prefer_upload_saver: true },
        { tw_kind: 'tw5', tw_version: '5.2.3', prefer_put_saver: true, prefer_upload_saver: true },

        # Unlikely edge case showing preference is ignored
        { tw_kind: 'classic', prefer_put_saver: true },
      ],

    }.each do |expected, list|
      list.each do |attrs|
        @site.update!({ prefer_upload_saver: false, prefer_put_saver: false }.merge(attrs))
        assert_equal expected, @site.use_put_saver?, attrs.inspect
      end
    end
  end

  test 'attachment behavior' do
    # To begin with, site has no content (which is not a
    # realistic scenario, but it's what we have in fixtures.)
    refute @site.saved_content_files.attached?

    # Upload some content
    @site.content_upload('foo123')

    # The new schema has an attachment now
    assert @site.saved_content_files.attached?

    # Sanity check the content
    assert_equal 'foo123', @site.file_download
  end

  def setup_some_saved_versions
    @site.content_upload('boop5')
    @site.content_upload('boop6')
    @boop6_blob_id = @site.reload.blob.id

    @site.content_upload('boop7')
    @boop7_blob_id = @site.reload.blob.id

    @site.content_upload('boop8')
    @boop8_blob_id = @site.reload.blob.id

    @site.content_upload('boop9')

    assert_equal 5, @site.reload.saved_content_files.count
  end

  test 'keep count uses the standard limit for site history users' do
    Setting.set_value(:keep_count_free, 4)
    Setting.set_value(:keep_count_standard, 8)

    assert_equal 4, @site.keep_count

    @site.user.update!(user_type: UserType.find_by!(name: 'superuser'))
    @site.reload

    assert @site.user.feature_enabled?(:site_history)
    assert_equal 8, @site.keep_count
  end

  test 'prune attachments keeps the same count as keep_count' do
    Setting.set_value(:keep_count_standard, 3)
    Setting.set_value(:history_daily_keep_days, 0)
    Setting.set_value(:history_session_keep_count, 0)
    @site.user.update!(user_type: UserType.find_by!(name: 'superuser'))
    @site.reload

    5.times { |i| @site.content_upload("version #{i}") }

    assert_equal 5, @site.reload.saved_content_files.count
    assert_equal 3, @site.keep_count

    @site.prune_attachments_now

    assert_equal 3, @site.reload.saved_content_files.count
    assert_equal 'version 4', @site.file_download
  end

  test 'prune keeps one snapshot per day' do
    setup_history_retention(keep_count: 2, daily_days: 30, session_count: 0)

    now = Time.current
    blob_ids = {
      newest:  create_version('newest',  at: now - 1.minute),
      second:  create_version('second',  at: now - 2.minutes),
      today:   create_version('today',   at: now - 3.minutes),
      y_new:   create_version('y_new',   at: now - 1.day),
      y_old:   create_version('y_old',   at: now - 1.day - 1.hour),
      d2_new:  create_version('d2_new',  at: now - 2.days),
      d2_old:  create_version('d2_old',  at: now - 2.days - 1.hour),
    }

    @site.prune_attachments_now

    remaining = @site.reload.saved_content_files.pluck(:blob_id)
    assert_equal 4, remaining.count

    # The recent buffer plus the last save of each older day survives.
    [blob_ids[:newest], blob_ids[:second], blob_ids[:y_new], blob_ids[:d2_new]].each do |blob_id|
      assert_includes remaining, blob_id
    end
    [blob_ids[:today], blob_ids[:y_old], blob_ids[:d2_old]].each do |blob_id|
      refute_includes remaining, blob_id
    end
  end

  test 'prune keeps the last save of each session' do
    setup_history_retention(keep_count: 2, daily_days: 0, session_count: 10)

    now = Time.current
    blob_ids = {
      newest:    create_version('newest',    at: now - 1.minute),
      second:    create_version('second',    at: now - 2.minutes),
      session_a: create_version('session_a', at: now - 2.hours),
      same_a:    create_version('same_a',    at: now - 2.hours - 10.minutes),
      session_b: create_version('session_b', at: now - 5.hours),
      same_b:    create_version('same_b',    at: now - 5.hours - 10.minutes),
    }

    @site.prune_attachments_now

    remaining = @site.reload.saved_content_files.pluck(:blob_id)
    assert_equal 4, remaining.count

    [blob_ids[:newest], blob_ids[:second], blob_ids[:session_a], blob_ids[:session_b]].each do |blob_id|
      assert_includes remaining, blob_id
    end
    [blob_ids[:same_a], blob_ids[:same_b]].each do |blob_id|
      refute_includes remaining, blob_id
    end
  end

  test 'prune keeps labeled versions outside the retention windows' do
    setup_history_retention(keep_count: 2, daily_days: 0, session_count: 0)

    blob_ids = 5.times.map { |i| create_version("labeled #{i}", at: Time.current - i.minutes) }
    oldest = @site.specific_saved_content_file(blob_ids.last)
    oldest.attachment_label = 'keep this one'
    oldest.save!

    @site.prune_attachments_now

    remaining = @site.reload.saved_content_files.pluck(:blob_id)
    assert_equal 3, remaining.count
    assert_includes remaining, blob_ids.last
    assert_equal 'labeled 0', @site.file_download(blob_ids.first)
  end

  test 'create restore point adds a labeled copy of the current content' do
    @site.content_upload('restore me')
    version_count = @site.reload.saved_version_count

    attachment = @site.create_restore_point!

    assert_equal version_count + 1, @site.reload.saved_version_count
    assert attachment.attachment_label.present?
    assert_equal 'restore me', @site.file_download
    assert_equal 'restore me', @site.file_download(attachment.blob_id)
  end

  test 'create restore point snapshots the SimpleWiki island' do
    site = new_site_helper(user: @site.user, name: 'restorepoint', empty: :simple)
    SimpleData.store!(site, '{"version":1,"seiten":[],"startseite":"","sprache":"de"}')
    version_count = site.reload.saved_version_count

    attachment = site.create_restore_point!

    assert_equal version_count + 1, site.reload.saved_version_count
    assert attachment.attachment_label.present?
    assert_equal '{"version":1,"seiten":[],"startseite":"","sprache":"de"}',
      site.simple_island_json_for_blob_id(attachment.blob_id)
  end

  # Tests are being skipped for now due to new logic
  # test 'prune attachments respects keep count', skip: true

  # test 'prune attachments respects keep count' do
  #   setup_some_saved_versions
  #
  #   @site.stubs(:keep_count).returns(100)
  #   @site.prune_attachments_now
  #   # All versions are kept
  #   assert_equal 5, @site.reload.saved_content_files.count
  #
  #   @site.stubs(:keep_count).returns(3)
  #   @site.prune_attachments_now
  #   # Three versions kept
  #   assert_equal 3, @site.reload.saved_content_files.count
  #
  #   # We can still access the current versions
  #   assert_equal 'boop9', @site.file_download
  #   assert_equal 'boop9', @site.file_download(@site.blob.id)
  #
  #   # We can access older versions by their blob id
  #   assert_equal 'boop8', @site.file_download(@boop8_blob_id)
  #   assert_equal 'boop7', @site.file_download(@boop7_blob_id)
  #
  #   # This one is gone now since we kept only three
  #   assert_nil @site.file_download(@boop6_blob_id)
  #
  #   # Create another site
  #   new_site = new_site_helper(name: 'newsite', user: @site.user)
  #   new_site_blob_id = new_site.blob.id
  #   assert_match(/UnaMesa Association/, new_site.file_download(new_site_blob_id))
  #
  #   # Can't access blobs from other sites
  #   assert_nil @site.file_download(new_site_blob_id)
  # end

  # Tests are being skipped for now due to new logic
  # test 'prune attachments considers labels', skip: true

  # test 'prune attachments considers labels' do
  #   setup_some_saved_versions
  #
  #   @site.stubs(:keep_count).returns(3)
  #   Settings::Features.stubs(:site_history_enabled?).returns(true)
  #
  #   # In the previous test we expected boop6 to be pruned
  #   # Here we'll give it a label and then confirm it is kept
  #   attachment = @site.specific_saved_content_file(@boop6_blob_id)
  #   attachment.attachment_label = 'some label'
  #   @site.prune_attachments_now
  #
  #   # As expected, boop6 was kept
  #   assert_equal 'boop6', @site.file_download(@boop6_blob_id)
  #
  #   # Actually the newer boop7 was pruned instead
  #   assert_nil @site.file_download(@boop7_blob_id)
  # end

  test 'prune job scheduled' do
    assert_enqueued_with(job: PruneAttachmentsJob) do
      @site.content_upload('foo123')
    end

    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(enqueued_jobs.first)
    # (It should use the default from Delayed::Worker.DEFAULT_MAX_ATTEMPTS, which is 25)
    assert_nil job_wrapper.max_attempts
  end

  test 'thumbnail job scheduled' do
    assert_enqueued_with(job: GenerateThumbnailJob) do
      @site.content_upload('foo123')
    end

    # See rails/config/initializers/active_job_delayed_job_param_fix.rb
    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(enqueued_jobs.last)
    assert_equal 1, job_wrapper.max_attempts
  end

  test 'thumbnail generation' do
    @site.content_upload('foo123')
    refute @site.thumbnail.present?
    GenerateThumbnailJob.perform_now('Site', @site.id)
    assert @site.reload.thumbnail.present?
    assert_equal 'image/png', @site.thumbnail.blob.content_type

    # Rendered with a 1920x1200 viewport and scaled down to 640x400.
    # Width and height are the first two big-endian integers in the PNG IHDR.
    width, height = @site.thumbnail.download[16, 8].unpack('NN')
    assert_equal [640, 400], [width, height]
  end

  test 'thumbnail storage service' do
    [
      [true, 'test1'],
      [false, 'test2'],

    ].each do |is_private, expected|
      @site.update(is_private:)
      @site.send(:thumbnail_attach, 'bogus')
      assert @site.thumbnail.present?
      assert_equal expected, @site.thumbnail.blob.service_name
    end
  end

  test 'switching storage service' do
    # Create three files with alternating storage services
    @site.update(storage_service: 'test1')
    @site.content_upload('foo123')

    @site.update(storage_service: 'test2')
    @site.content_upload('bar123')

    @site.update(storage_service: 'test')
    @site.content_upload('baz123')

    # Sanity check
    assert_equal 3, @site.saved_content_files.count
    assert_equal(%w[test1 test2 test], @site.saved_content_files.map { |f| f.blob.service_name })
    assert_equal 'test', @site.current_content.blob.service_name
    assert_equal 'baz123', @site.uncached_file_download

    # Delete the current file and sanity check
    @site.current_content.purge
    assert_equal 'test2', @site.reload.current_content.blob.service_name
    assert_equal 'bar123', @site.uncached_file_download

    # Delete the current file and sanity check
    @site.current_content.purge
    assert_equal 'test1', @site.reload.current_content.blob.service_name
    assert_equal 'foo123', @site.uncached_file_download
  end

  test 'blob missing in storage' do
    # It's a little confusing, but `main_blob_missing?` is true if there is a
    # blob record but the storage service lost the file for it. So if we have
    # no blob records at all then it's false. This is an edge case, since sites
    # with zero saved versions in general don't exist.
    assert_equal 0, @site.saved_version_count
    assert_not @site.main_blob_missing?

    # Upload some content so we do have a blob
    @site.content_upload('test content')
    assert_equal 1, @site.saved_version_count
    blob = @site.reload.blob

    # The blob is present in the storage service
    assert WithSavedContent.blob_exists_in_storage?(blob)
    assert_not @site.main_blob_missing?

    # The blob is missing in the storage service
    blob.service.stubs(:exist?).returns(false)
    assert_not WithSavedContent.blob_exists_in_storage?(blob)
    assert @site.main_blob_missing?
  end

  test 'restore missing main blob' do
    # Create two saved versions
    @site.content_upload('older version')
    old_blob = @site.reload.blob
    @site.content_upload('current version')

    # Sanity check
    assert_equal 2, @site.reload.saved_version_count
    assert_equal 'current version', @site.file_download

    # Main blob is not missing, no restore is done
    assert_raises(RuntimeError, "Main blob not missing!") do
      @site.reload.restore_missing_main_blob!
    end

    # Main blob is missing, but no non-missing other blob was found
    WithSavedContent.stub(:blob_exists_in_storage?, ->(_blob) { false }) do
      assert_raises(RuntimeError, "No good blob found!") do
        @site.reload.restore_missing_main_blob!
      end
    end

    # Main blob missing, and there is an non-missing older blob available
    WithSavedContent.stub(:blob_exists_in_storage?, ->(blob) { blob.id == old_blob.id }) do
      @site.reload.restore_missing_main_blob!

      # Should have created a new version with the older content
      assert_equal 3, @site.reload.saved_content_files.count
      assert_equal 'older version', @site.file_download
    end
  end

  test 'tagging basic functionality' do
    # Initially no tags
    assert @site.tag_list.empty?
    assert_equal 0, @site.tags.count

    # Add some tags
    @site.tag_list.add('ruby', 'rails', 'web-development')
    @site.save!

    # Verify tags were added
    @site.reload
    assert_equal 3, @site.tags.count
    assert_includes @site.tag_list, 'ruby'
    assert_includes @site.tag_list, 'rails'
    assert_includes @site.tag_list, 'web-development'

    # Remove a tag
    @site.tag_list.remove('rails')
    @site.save!

    # Verify tag was removed
    @site.reload
    assert_equal 2, @site.tags.count
    assert_includes @site.tag_list, 'ruby'
    assert_not_includes @site.tag_list, 'rails'
    assert_includes @site.tag_list, 'web-development'
  end

  test 'tag search functionality' do
    # Create another site for testing search
    other_site = new_site_helper(name: 'othersite', user: @site.user)

    # Add tags to both sites
    @site.tag_list = ['ruby', 'rails', 'programming']
    @site.save!

    other_site.tag_list = ['javascript', 'nodejs', 'programming']
    other_site.save!

    # Search for sites with 'ruby' tag
    ruby_sites = Site.search_tags('ruby')
    assert_includes ruby_sites, @site
    assert_not_includes ruby_sites, other_site

    # Search for sites with 'programming' tag
    programming_sites = Site.search_tags('programming')
    assert_includes programming_sites, @site
    assert_includes programming_sites, other_site

    # Search for sites with 'nonexistent' tag
    nonexistent_sites = Site.search_tags('nonexistent')
    assert_not_includes nonexistent_sites, @site
    assert_not_includes nonexistent_sites, other_site

    # Search with multiple words (any match)
    multiple_sites = Site.search_tags('ruby javascript')
    assert_includes multiple_sites, @site
    assert_includes multiple_sites, other_site
  end

  test 'tag list manipulation' do
    # Test setting tag list as string
    @site.tag_list = 'foo, bar, baz'
    @site.save!

    @site.reload
    assert_equal 3, @site.tags.count
    assert_includes @site.tag_list, 'foo'
    assert_includes @site.tag_list, 'bar'
    assert_includes @site.tag_list, 'baz'

    # Test setting tag list as array
    @site.tag_list = ['one', 'two', 'three']
    @site.save!

    @site.reload
    assert_equal 3, @site.tags.count
    assert_includes @site.tag_list, 'one'
    assert_includes @site.tag_list, 'two'
    assert_includes @site.tag_list, 'three'
    assert_not_includes @site.tag_list, 'foo'
  end

  private

  def setup_history_retention(keep_count:, daily_days:, session_count:)
    @site.user.update!(user_type: UserType.find_by!(name: 'superuser'))
    Setting.set_value(:keep_count_standard, keep_count)
    Setting.set_value(:history_daily_keep_days, daily_days)
    Setting.set_value(:history_session_gap_minutes, 30)
    Setting.set_value(:history_session_keep_count, session_count)
    @site.reload
  end

  def create_version(content, at:)
    @site.content_upload(content)
    @site.reload
    attachment = @site.saved_content_files.order(id: :desc).first
    attachment.update_column(:created_at, at)
    attachment.blob.update_column(:created_at, at)
    attachment.blob_id
  end
end
