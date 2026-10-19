class CreateSimpleData < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_data do |t|
      t.references :site, null: false, foreign_key: true, index: { unique: true }
      t.text :json, null: false

      t.timestamps
    end

    create_table :simple_data_versions do |t|
      t.references :site, null: false, foreign_key: true, index: true
      t.text :json, null: false
      t.datetime :created_at, null: false
    end
  end
end
