class WikiCollaborator < ApplicationRecord
  belongs_to :site, inverse_of: :wiki_collaborators

  has_secure_password

  validates :name, presence: true, length: { maximum: 100 }
  validates :password_digest, presence: true
  validates :enabled, inclusion: { in: [true, false] }

  def self.authenticate_for_site(site, name, password)
    collaborator = site.wiki_collaborators.find_by(name: name, enabled: true)
    return nil unless collaborator&.authenticate(password)

    collaborator
  end
end