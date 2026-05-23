class AddCookieConsentEnabledToSites < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :cookie_consent_enabled, :boolean, default: false, null: false
    add_column :sites, :cookie_consent_version, :integer, default: 1, null: false
  end
end
