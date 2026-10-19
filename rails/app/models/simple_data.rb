class SimpleData < ApplicationRecord
  belongs_to :site

  validates :json, presence: true

  # Save a new content version and keep a bounded history, mirroring the
  # keep_count logic used for the wiki shell history.
  def self.store!(site, new_json)
    record = site.simple_data || site.build_simple_data
    record.json = new_json
    record.save!

    site.simple_data_versions.create!(json: new_json, created_at: Time.current)
    prune_versions!(site, site.keep_count)

    record
  end

  def self.prune_versions!(site, keep)
    site.simple_data_versions.
      order(created_at: :desc).
      offset(keep).
      each(&:destroy)
  end

  # ETag derived from the current content so clients can detect conflicts.
  def etag
    Digest::MD5.hexdigest(json.to_s)
  end
end
