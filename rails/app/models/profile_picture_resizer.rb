# Scales an oversized upload down so it still fits the profile-picture limits.
#
# Returns an ActiveStorage-compatible Hash attachable on success, or nil when
# resizing is unavailable/fails. The caller then keeps the original file and
# the regular validations decide what happens.
class ProfilePictureResizer
  def self.call(attachable, max_dimension:, allowed_content_types:)
    new(attachable, max_dimension:, allowed_content_types:).call
  end

  def initialize(attachable, max_dimension:, allowed_content_types:)
    @attachable = attachable
    @max_dimension = max_dimension
    @allowed_content_types = allowed_content_types
  end

  def call
    return nil unless allowed_content_type?

    @io = ProfilePictureDimensions.io_from(@attachable)
    return nil unless @io&.respond_to?(:read)

    @io.rewind if @io.respond_to?(:rewind)
    resized = pipeline.call
    resized.rewind if resized.respond_to?(:rewind)

    { io: resized, filename: filename, content_type: content_type }
  rescue LoadError => error
    log_failure(error)
    nil
  rescue StandardError => error
    log_failure(error)
    nil
  end

  private

  def pipeline
    require 'image_processing/mini_magick'

    ImageProcessing::MiniMagick
      .source(source)
      .resize_to_limit(@max_dimension, @max_dimension)
  end

  # ImageProcessing needs a path-based source. Uploaded files already have one;
  # plain IOs (e.g. API callers) are spooled to a temp file first.
  def source
    return @io if @io.respond_to?(:path) && @io.path.present? && File.exist?(@io.path)

    require 'tempfile'
    extension = File.extname(filename).presence || '.img'
    @source_tempfile = Tempfile.new(['profile-picture-source', extension])
    @source_tempfile.binmode
    @io.rewind if @io.respond_to?(:rewind)
    IO.copy_stream(@io, @source_tempfile)
    @source_tempfile.flush
    @source_tempfile.rewind
    @source_tempfile
  end

  def allowed_content_type?
    content_type.nil? || @allowed_content_types.include?(content_type)
  end

  def content_type
    @content_type ||= ProfilePictureDimensions.content_type_from(@attachable)
  end

  def filename
    name =
      if @attachable.respond_to?(:original_filename)
        @attachable.original_filename
      elsif @attachable.is_a?(Hash)
        @attachable[:filename] || @attachable['filename']
      elsif @attachable.respond_to?(:path)
        File.basename(@attachable.path)
      end

    File.basename(name.presence || 'profile-picture')
  end

  def log_failure(error)
    Rails.logger.warn("Profile picture resize failed: #{error.class}: #{error.message}")
  end
end
