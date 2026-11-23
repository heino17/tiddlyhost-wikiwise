class User < ApplicationRecord
  include AdminSearchable
  include Subscriber

  before_validation :set_default_role, on: :create

  def set_default_role
    self.user_type_id ||= UserType.find_by(name: "basic")&.id
  end

  attr_accessor :skip_password_validation

  def password_required?
    return false if skip_password_validation

    super
  end

  PREFERENCES = {
    list_mode: %w[list grid],
    theme_mode: ThemeModeHelper::MODES,
  }
  include WithPreferences

  #
  # Include devise modules. Others available are:
  # :omniauthable
  #
  # Using :secure_validatable from devise-security instead of
  # :validateable from standard devise, but with email_validation
  # turned off.
  #
  # There are also some other modules in devise-security that
  # we're not using.
  #
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :secure_validatable, email_validation: false

  belongs_to :user_type

  validates_presence_of :name

  PROFILE_PICTURE_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  PROFILE_PICTURE_MAX_BYTES = 100.kilobytes
  PROFILE_PICTURE_MAX_DIMENSION = 256

  has_one_attached :profile_picture

  attr_accessor :remove_profile_picture

  attr_reader :profile_picture_dimensions

  validate :validate_profile_picture
  after_save :purge_profile_picture_if_requested, :clear_profile_picture_assignment

  # Read the dimensions before ActiveStorage unfurls the blob. Oversized
  # pictures are scaled down here so users get a working upload instead of an
  # error; the regular validations still catch bad types and file sizes.
  def profile_picture=(attachable)
    @profile_picture_assigned = attachable.present?

    if @profile_picture_assigned
      dimensions = ProfilePictureDimensions.from(attachable)
      if dimensions&.any? { |value| value > PROFILE_PICTURE_MAX_DIMENSION }
        resized = ProfilePictureResizer.call(
          attachable,
          max_dimension: PROFILE_PICTURE_MAX_DIMENSION,
          allowed_content_types: PROFILE_PICTURE_CONTENT_TYPES,
        )
        attachable = resized if resized
      end
      @profile_picture_dimensions = ProfilePictureDimensions.from(attachable)
    else
      @profile_picture_dimensions = nil
    end

    super
  end

  has_many :sites, dependent: :destroy
  has_many :tspot_sites, dependent: :nullify

  # Comment & Voting
  has_many :comments, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_many :site_votes, dependent: :destroy

  def all_sites
    return sites unless Settings.tiddlyspot_enabled?

    sites + tspot_sites
  end

  validates :username,
    uniqueness: {
      case_sensitive: false,
      allow_blank: true,
    },
    length: {
      minimum: 3,
      maximum: 30,
      allow_blank: true,
    },
    format: {
      # Must be upper- or lowercase letters, numerals, and dashes
      # Must not have more than one consecutive dash
      # Must not start or end with a dash
      # (See also app/javascript/packs/application.js)
      without: / [^A-Za-z0-9-] | -- | ^- | -$ /x,
      message: "'%<value>s' is not allowed. Please choose a different username.",
    }

  scope :signed_in_never,          ->        { where(sign_in_count: 0) }
  scope :signed_in_once,           ->        { where(sign_in_count: 1) }
  scope :signed_in_more_than,      ->(times) { where('sign_in_count > ?', times) }
  scope :signed_in_more_than_once, ->        { signed_in_more_than(1) }
  scope :signed_in_since,          ->(time)  { where('current_sign_in_at >= ?', time) }
  scope :active_day,               ->        { signed_in_since(1.day.ago) }
  scope :active_week,              ->        { signed_in_since(1.week.ago) }
  scope :active_month,             ->        { signed_in_since(1.month.ago) }

  after_create :local_dev_first_user_upgrade if Rails.env.development?

  def username_or_name
    username.presence || name
  end

  def username_or_email
    username.presence || email
  end

  def short_name
    name.split(/\s+/).first
  end

  def email_change_in_progress?
    unconfirmed_email.present?
  end

  # Unused. Delete maybe?
  scope :with_type,    ->(*type_names) { where(user_type_id: UserType.where(name: type_names.map(&:to_s)).pluck(:id)) }
  scope :without_type, ->(*type_names) { where.not(user_type_id: UserType.where(name: type_names.map(&:to_s)).pluck(:id)) }

  scope :search_for, lambda { |search_text|
    where("#{table_name}.name ILIKE CONCAT('%',?::text,'%')", search_text).
    or(where("#{table_name}.username ILIKE CONCAT('%',?::text,'%')", search_text)).
    or(where("#{table_name}.email ILIKE CONCAT('%',?::text,'%')", search_text)) }

  # Not sure if we could use an assocation here or at least some clever joins, but this seems to work okay
  def site_attachments
    ActiveStorage::Attachment.where(record_id: sites.pluck(:id), record_type: 'Site')
  end

  def site_blobs
    ActiveStorage::Blob.where(id: site_attachments.pluck(:blob_id))
  end

  def total_storage_bytes
    sites.sum(:raw_byte_size) + tspot_sites.sum(:raw_byte_size)
    # site_blobs.sum(:byte_size)
  end

  def has_user_type?(user_type_name)
    user_type.name == user_type_name.to_s
  end

  def has_username?
    username.present?
  end

  def hub_sites_count
    sites.for_hub.count + tspot_sites.for_hub.count
  end

  def has_hub_sites?
    hub_sites_count > 0
  end

  def has_hub_link?
    has_hub_sites? && has_username?
  end

  def is_superuser?
    has_user_type?(:superuser)
  end

  def is_admin?
    is_superuser?
  end

  # A freshly assigned upload has a blob that isn't persisted until save.
  # Only serve pictures that are actually available through ActiveStorage.
  def has_profile_picture?
    profile_picture.attached? && profile_picture.blob.persisted?
  end

  def use_avatar?
    has_profile_picture? || use_gravatar? || use_libravatar?
  end

  private

  def validate_profile_picture
    return unless profile_picture.attached?
    return unless @profile_picture_assigned

    blob = profile_picture.blob
    return if blob.nil?

    unless PROFILE_PICTURE_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:profile_picture, I18n.t('user_update_account_profile_picture_error_type'))
    end

    if blob.byte_size.to_i > PROFILE_PICTURE_MAX_BYTES
      errors.add(:profile_picture, I18n.t('user_update_account_profile_picture_error_size'))
    end

    dimensions = @profile_picture_dimensions
    if dimensions && dimensions.any? { |value| value.to_i > PROFILE_PICTURE_MAX_DIMENSION }
      errors.add(:profile_picture,
        I18n.t('user_update_account_profile_picture_error_dimensions', max: PROFILE_PICTURE_MAX_DIMENSION))
    end
  end

  def purge_profile_picture_if_requested
    return unless ActiveModel::Type::Boolean.new.cast(remove_profile_picture)

    profile_picture.purge
    self.remove_profile_picture = false
  end

  def clear_profile_picture_assignment
    @profile_picture_assigned = false
  end

  public

  def is_tiddlyhost?
    email == Settings.tiddlyhost_account_email
  end

  def feature_enabled?(feature_name)
    Settings.feature_enabled?(feature_name, self)
  end

  # The default is set in config/initializers/devise
  def timeout_in
    return 12.hours if is_admin?

    super
  end

  # https://www.rubydoc.info/github/plataformatec/devise/Devise/Models/Confirmable#after_confirmation-instance_method
  def after_confirmation
    th_log("Account #{id} #{email} confirmation")
  end

  def local_dev_first_user_upgrade
    # Only in development mode...
    return unless Rails.env.development?

    # Only for the first user created...
    return unless User.count == 1

    # Upgrade to admin user
    update(user_type: UserType.superuser)

    # And skip the devise email confirmation
    skip_confirmation!
  end
end
