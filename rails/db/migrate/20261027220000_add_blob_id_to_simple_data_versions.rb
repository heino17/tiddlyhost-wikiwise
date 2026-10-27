class AddBlobIdToSimpleDataVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :simple_data_versions, :blob_id, :string
    add_index :simple_data_versions, :blob_id
  end
end
