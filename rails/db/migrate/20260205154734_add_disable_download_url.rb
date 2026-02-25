class AddDisableDownloadUrl < ActiveRecord::Migration[7.2]
  def change
    add_column :sites, :disable_download_url, :boolean, default: false

    # (Skipping `add_column :tspot_sites` because I don't want to add new
    # features for legacy Tiddlyspot)
  end
end