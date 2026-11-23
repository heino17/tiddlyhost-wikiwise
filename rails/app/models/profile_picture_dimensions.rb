# Extracts image dimensions from the first bytes of an uploaded file.
#
# Kept dependency-free on purpose: only the few bytes needed for the header
# are read, so deciding whether a picture needs resizing stays cheap and does
# not depend on ImageMagick being available.
class ProfilePictureDimensions
  MAX_READ_BYTES = 128.kilobytes

  class << self
    def from(attachable)
      io = io_from(attachable)
      return nil unless io

      rewindable = io.respond_to?(:rewind)
      io.rewind if rewindable
      bytes = io.read(MAX_READ_BYTES)
      io.rewind if rewindable
      return nil if bytes.blank?

      from_bytes(bytes.b, content_type_from(attachable))
    rescue StandardError
      nil
    end

    def from_bytes(bytes, content_type = nil)
      return nil if bytes.blank?

      case content_type
      when 'image/png'   then png(bytes)
      when 'image/gif'   then gif(bytes)
      when 'image/jpeg'  then jpeg(bytes)
      when 'image/webp'  then webp(bytes)
      else
        png(bytes) || gif(bytes) || jpeg(bytes) || webp(bytes)
      end
    end

    def io_from(attachable)
      return attachable.tempfile if attachable.respond_to?(:tempfile)
      return attachable[:io] || attachable['io'] if attachable.is_a?(Hash)
      return attachable if attachable.respond_to?(:read)

      nil
    end

    def content_type_from(attachable)
      return attachable.content_type if attachable.respond_to?(:content_type)
      return attachable[:content_type] || attachable['content_type'] if attachable.is_a?(Hash)

      nil
    end

    private

    def png(bytes)
      return nil unless bytes.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
      return nil unless bytes.byteslice(12, 4) == 'IHDR'
      return nil unless bytes.bytesize >= 24

      bytes.byteslice(16, 8).unpack('N2')
    end

    def gif(bytes)
      return nil unless %w[GIF87a GIF89a].include?(bytes.byteslice(0, 6))
      return nil unless bytes.bytesize >= 10

      bytes.byteslice(6, 4).unpack('v2')
    end

    def jpeg(bytes)
      return nil unless bytes.byteslice(0, 2) == "\xFF\xD8".b

      index = 2
      while index + 3 < bytes.bytesize
        index += 1 while bytes.getbyte(index) == 0xFF && index < bytes.bytesize
        return nil if index >= bytes.bytesize

        marker = bytes.getbyte(index)
        index += 1
        return nil if marker == 0xD9 || marker == 0xDA
        next if marker == 0x01 || (0xD0..0xD7).cover?(marker)
        return nil if index + 1 >= bytes.bytesize

        length = bytes.byteslice(index, 2).unpack1('n')
        return nil if length < 2 || index + length > bytes.bytesize

        if sof_marker?(marker)
          return nil if length < 7

          height = bytes.byteslice(index + 3, 2).unpack1('n')
          width = bytes.byteslice(index + 5, 2).unpack1('n')
          return [width, height]
        end

        index += length
      end

      nil
    end

    def sof_marker?(marker)
      (0xC0..0xCF).cover?(marker) && ![0xC4, 0xC8, 0xCC].include?(marker)
    end

    def webp(bytes)
      return nil unless bytes.byteslice(0, 4) == 'RIFF' && bytes.byteslice(8, 4) == 'WEBP'

      case bytes.byteslice(12, 4)
      when 'VP8X' then webp_extended(bytes)
      when 'VP8 ' then webp_lossy(bytes)
      when 'VP8L' then webp_lossless(bytes)
      end
    end

    def webp_extended(bytes)
      return nil unless bytes.bytesize >= 30

      [le24(bytes, 24) + 1, le24(bytes, 27) + 1]
    end

    def webp_lossy(bytes)
      return nil unless bytes.bytesize >= 30
      return nil unless bytes.byteslice(23, 3) == "\x9D\x01\x2A".b

      width = bytes.byteslice(26, 2).unpack1('v') & 0x3FFF
      height = bytes.byteslice(28, 2).unpack1('v') & 0x3FFF
      [width, height]
    end

    def webp_lossless(bytes)
      return nil unless bytes.bytesize >= 25
      return nil unless bytes.getbyte(20) == 0x2F

      b1, b2, b3, b4 = bytes.byteslice(21, 4).bytes
      width = (b1 | ((b2 & 0x3F) << 8)) + 1
      height = (((b2 & 0xC0) >> 6) | (b3 << 2) | ((b4 & 0x0F) << 10)) + 1
      [width, height]
    end

    def le24(bytes, offset)
      bytes.getbyte(offset) |
        (bytes.getbyte(offset + 1) << 8) |
        (bytes.getbyte(offset + 2) << 16)
    end
  end
end
