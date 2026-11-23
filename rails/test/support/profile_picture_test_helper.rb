require 'tempfile'
require 'zlib'

module ProfilePictureTestHelper
  def uploaded_png(width:, height:, content_type: 'image/png', padding: 0)
    file = Tempfile.new(['avatar', '.png'])
    file.binmode
    file.write(png_bytes(width, height) + ('x' * padding))
    file.flush
    (@profile_picture_files ||= []) << file

    Rack::Test::UploadedFile.new(
      file.path, content_type, true, original_filename: 'avatar.png'
    )
  end

  def uploaded_text
    file = Tempfile.new(['avatar', '.txt'])
    file.binmode
    file.write('not an image')
    file.flush
    (@profile_picture_files ||= []) << file

    Rack::Test::UploadedFile.new(
      file.path, 'text/plain', false, original_filename: 'avatar.txt'
    )
  end

  private

  def png_bytes(width, height)
    ihdr = [width, height, 8, 6, 0, 0, 0].pack('NNC5')
    "\x89PNG\r\n\x1A\n".b +
      png_chunk('IHDR', ihdr) +
      png_chunk('IDAT', Zlib::Deflate.deflate('')) +
      png_chunk('IEND', '')
  end

  def png_chunk(type, data)
    [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
  end
end
