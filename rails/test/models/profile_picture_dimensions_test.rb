require 'test_helper'

class ProfilePictureDimensionsTest < ActiveSupport::TestCase
  test 'reads PNG dimensions' do
    png = "\x89PNG\r\n\x1A\n".b + [13].pack('N') + 'IHDR' + [64, 32].pack('N2') + "\x00" * 8

    assert_equal [64, 32], ProfilePictureDimensions.from_bytes(png, 'image/png')
  end

  test 'reads JPEG dimensions from the first SOF marker' do
    jpeg = "\xFF\xD8".b +
      "\xFF\xC0".b + [10].pack('n') + [8].pack('C') + [50, 100].pack('n2') +
      "\x01\x11\x00".b + "\xFF\xD9".b

    assert_equal [100, 50], ProfilePictureDimensions.from_bytes(jpeg, 'image/jpeg')
  end

  test 'reads GIF dimensions' do
    gif = 'GIF89a' + [30, 20].pack('v2') + "\x00" * 4

    assert_equal [30, 20], ProfilePictureDimensions.from_bytes(gif, 'image/gif')
  end

  test 'reads extended WebP dimensions' do
    webp = riff_webp('VP8X') + "\x00" * 4 + [79, 0, 0].pack('C3') + [39, 0, 0].pack('C3')

    assert_equal [80, 40], ProfilePictureDimensions.from_bytes(webp, 'image/webp')
  end

  test 'reads lossy WebP dimensions' do
    webp = riff_webp('VP8 ') + "\x00\x00\x00".b + "\x9D\x01\x2A".b +
      [100].pack('v') + [50].pack('v')

    assert_equal [100, 50], ProfilePictureDimensions.from_bytes(webp, 'image/webp')
  end

  test 'reads lossless WebP dimensions' do
    webp = riff_webp('VP8L') + "\x2F\x4F\xC0\x09\x00".b

    assert_equal [80, 40], ProfilePictureDimensions.from_bytes(webp, 'image/webp')
  end

  test 'returns nil for unknown data' do
    assert_nil ProfilePictureDimensions.from_bytes('just some text', 'text/plain')
  end

  private

  def riff_webp(fourcc)
    'RIFF' + [1024].pack('V') + 'WEBP' + fourcc + [256].pack('V')
  end
end
