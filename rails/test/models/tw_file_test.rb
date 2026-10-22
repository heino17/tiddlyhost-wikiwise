require 'test_helper'

class TwFileTest < ActiveSupport::TestCase
  test 'adding a tiddler' do
    tw = TwFile.new(minimal_html(:tw5))
    tw.write_tiddlers({ 'foo' => 'bar' })

    assert_match '<div id="storeArea"><div title="foo"><pre>bar</pre></div></div>', tw.to_html
    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal 'bar', TwFile.new(tw.to_html).tiddler_content('foo')
  end

  test 'adding a tiddler with json script store' do
    tw = TwFile.new(minimal_html(:tw5_json))
    tw.write_tiddlers({ 'foo' => 'bar' })

    # We add tiddlers by appending a new script element
    assert_match '<script class="tiddlywiki-tiddler-store" type="application/json">[{"text":"bar","title":"foo"}]</script>', tw.to_html

    # The original script element store area is still there
    assert_match '<script class="tiddlywiki-tiddler-store" type="application/json">[]</script>', tw.to_html

    # The old storeArea is present also but with no content
    assert_match '<div id="storeArea"></div>', tw.to_html

    # So we notice the new content
    tw = TwFile.new(tw.to_html)

    assert_equal 'bar', tw.tiddler_content('foo')
    assert_equal([{ 'text' => 'bar', 'title' => 'foo' }], tw.tiddlers_data)
    assert_equal([{ 'title' => 'foo' }], tw.tiddlers_data(skinny: true))
  end

  test 'tiddlyhost mods for tw5' do
    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite').tap do |tw|
      {
        '$:/UploadURL' => 'http://coolsite.tiddlyhost-test-example.com',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end

      assert_equal 'coolsite', tw.get_site_name
    end

    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite', for_download: true).tap do |tw|
      {
        '$:/UploadURL' => '',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end

      # We can't get the name without $:/UploadURL...
      assert_nil tw.get_site_name
    end

    ThFile.from_empty(:tw5).apply_tiddlyhost_mods('coolsite', use_put_saver: true).tap do |tw|
      {
        '$:/UploadURL' => '',
        '$:/UploadWithUrlOnly' => 'yes',
        '$:/config/AutoSave' => 'no',

      }.each do |tiddler_name, expected_content|
        assert_equal expected_content, tw.tiddler_content(tiddler_name)
      end
    end
  end

  test 'tiddlyhost mods for classic' do
    ThFile.from_empty(:classic).apply_tiddlyhost_mods('coolsite').tap do |tw|
      [
        ['ThostUploadPlugin', false, "bidix.initOption('txtThostSiteName','coolsite');"],
        ['ThostUploadPlugin', false, "bidix.thostUpload.uploadChanges('#{Settings.subdomain_site_url("' + siteName + '")}');"],
        ['ThostUploadPlugin', false, 'config.macros.thostUpload = {'],
        ['TiddlyHost', true, 'is a hosting service for ~TiddlyWiki'],

      ].each do |tiddler_name, shadow, include_string|
        tiddler_content = tw.tiddler_content(tiddler_name, shadow:)
        assert_includes tiddler_content, include_string
      end

      assert_equal 'coolsite', tw.get_site_name
    end
  end

  test 'tiddlyhost mods do nothing for an encrypted tiddlywiki' do
    tw = ThFile.new(minimal_html(:encrypted))
    original_html = tw.to_html
    assert_equal original_html, tw.apply_tiddlyhost_mods('foo').to_html
  end

  test 'tiddlywiki validation' do
    # Valid files
    %w[tw5 encrypted classic].each do |type|
      tw_file = TwFile.new(minimal_html(type))
      assert tw_file.looks_valid?

      # Some extra sanity checks
      assert tw_file.tiddlywiki_title.present?
      assert tw_file.tiddlywiki_version.present?
      assert_equal tw_file.is_classic?, tw_file.tiddlywiki_title_classic.present?
      assert_equal tw_file.is_classic?, tw_file.tiddlywiki_version_classic.present?
      assert_equal tw_file.is_tw5?, tw_file.tiddlywiki_title_tw5.present?
      assert_equal tw_file.is_tw5?, tw_file.tiddlywiki_version_tw5.present?
    end

    # Invalid files
    [
      ['Area', 'Aria'],
      ['TiddlyWiki', 'HackyWiki'],
      ['application-name', 'app-name', true],

    ].each do |match, replace, skip_classic|
      [
        :tw5,
        :encrypted,
        (:classic unless skip_classic),

      ].compact.each do |type|
        refute TwFile.new(minimal_html(type).sub(match, replace)).looks_valid?
      end
    end

    # Garbage data
    refute TwFile.new(File.read("#{Rails.root}/app/assets/images/favicon.ico")).looks_valid?
  end

  test 'light get version' do
    # Test with real empty files
    for_all_empties do |empty_file, tw_kind, tw_version|
      assert_equal [tw_kind, tw_version], TwFile.light_get_kind_and_version(File.read(empty_file))
    end

    # Test with the minimal test html files too I guess
    # (Maybe we can ditch these...)
    [
      [:tw5, '5.1.24-prerelease'],
      [:classic, '2.9.2'],
    ].each do |type, expected_version|
      assert_equal [type.to_s, expected_version], TwFile.light_get_kind_and_version(minimal_html(type))
    end
  end

  # Test the "heavy" version of determining the kind by parsing the html
  test 'get kind' do
    for_all_kinds do |tw_kind|
      next if tw_kind == "prerelease"

      empty = Empty.find_by_name(tw_kind)
      assert empty, "No empty found for kind #{tw_kind}!"
      assert_equal(tw_kind, empty.kind, "Derived kind was #{empty.kind}, expecting #{tw_kind}!")
    end
  end

  test 'simplewiki detection' do
    tw = ThFile.from_empty(:simple)
    assert tw.is_simple?
    assert_equal 'simple', tw.kind
    refute tw.is_tw5?
    assert tw.looks_valid?
    assert_equal '0.1.52', tw.tiddlywiki_version
    assert tw.simple_island_content.present?

    # Light detection matches too
    assert_equal ['simple', '0.1.52'],
      TwFile.light_get_kind_and_version(File.read(ThFile.empty_path(:simple)))
  end

  test 'simplewiki mods replace island and add server metas when serving' do
    th_file = ThFile.from_empty(:simple)
    th_file.apply_simple_mods('coolsite', island_json: '{"seiten":[{"titel":"A"}]}',
      display_name: 'Mein Wiki', subtitle: 'Klein und fein')

    assert_equal '{"seiten":[{"titel":"A"}]}', th_file.simple_island_content
    assert_equal 'Mein Wiki', th_file.get_meta('simplewiki-title')
    assert_equal 'Klein und fein', th_file.get_meta('simplewiki-subtitle')
    assert_equal 'tiddlyhost', th_file.get_meta('simplewiki-server')
    assert_equal 'http://coolsite.tiddlyhost-test-example.com/simplewiki/status',
      th_file.get_meta('simplewiki-status-url')
    assert_equal 'http://coolsite.tiddlyhost-test-example.com/simplewiki/data',
      th_file.get_meta('simplewiki-data-url')

    th_file.apply_simple_mods('coolsite', island_json: '{"seiten":[]}',
      display_name: 'Neu', subtitle: '')
    assert_equal 'Neu', th_file.get_meta('simplewiki-title')
    assert_nil th_file.get_meta('simplewiki-subtitle')
    assert_equal 1, th_file.to_html.scan('<meta name="simplewiki-title"').count
  end

  test 'simplewiki shell keeps vue event attributes when served' do
    th_file = ThFile.from_empty(:simple)
    th_file.apply_simple_mods('coolsite', island_json: '{"seiten":[]}')

    html = th_file.to_html
    assert_includes html, '@click="toggleTheme"'
    assert_includes html, '@click="openSettings"'
  end

  test 'simplewiki mods for download keep island and title but add no server metas' do
    th_file = ThFile.from_empty(:simple)
    th_file.apply_simple_mods('coolsite', for_download: true, island_json: '{"seiten":[]}',
      display_name: 'Mein Wiki', subtitle: 'Klein und fein')

    assert_equal '{"seiten":[]}', th_file.simple_island_content
    assert_equal 'Mein Wiki', th_file.get_meta('simplewiki-title')
    assert_equal 'Klein und fein', th_file.get_meta('simplewiki-subtitle')
    assert_nil th_file.get_meta('simplewiki-server')
    assert_nil th_file.get_meta('simplewiki-status-url')
  end

  test 'simplewiki island escapes script-closing sequences' do
    th_file = ThFile.from_empty(:simple)
    th_file.apply_simple_mods('coolsite', island_json: '{"seiten":[{"text":"</script>"}]}')

    refute_match '</script>', th_file.simple_island_content
    assert_match '\u003c/script>', th_file.simple_island_content
  end

  test 'robust version' do
    th_file = ThFile.from_empty(:tw5x)
    th_file.stubs(:tiddlywiki_version).returns('11.1.2')
    assert_equal '11.1.2', th_file.robust_version.to_s
    assert th_file.version_higher_than?('9.8.7')
    assert_not th_file.version_higher_than?('11.1.3-preview')
  end

  test 'external script tag' do
    for_all_empties do |empty_file, tw_kind, tw_version|
      next unless tw_kind == 'tw5x'

      th_file = ThFile.from_file(empty_file)

      original_tag = th_file.external_core_script_tag
      assert original_tag.present?, "Can't find script tag for #{tw_kind} version #{tw_version}"
      assert_equal "tiddlywikicore-#{tw_version}.js", original_tag['src']

      modified_tag = th_file.inject_external_core_url_prefix.external_core_script_tag
      assert_equal "http://tiddlyhost-test-example.com/tiddlywikicore-#{tw_version}.js", modified_tag['src']
    end
  end

  test 'autosave behavior' do
    [
      [:tw5, false, 'no'],
      [:tw5x, true, 'yes'],

    ].each do |empty, external_core, expected|
      # Create new tiddlywiki
      th_file = ThFile.from_empty(empty)

      # Sanity check whether it is external core
      assert_equal external_core, th_file.is_external_core?

      # Attempt to turn autosave on
      th_file.write_tiddlers({ '$:/config/AutoSave' => 'yes' })

      # Apply the usual processing done when serving a site
      th_file.apply_tiddlyhost_mods('foo')

      # Confirm the auto save value
      assert_equal expected, th_file.tiddler_content('$:/config/AutoSave')
    end
  end

  def minimal_html(type)
    File.read("test/data/minimal_#{type}.html")
  end
end
