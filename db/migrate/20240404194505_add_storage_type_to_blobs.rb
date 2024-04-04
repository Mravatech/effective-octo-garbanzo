class AddStorageTypeToBlobs < ActiveRecord::Migration[7.1]
  def change
    add_column :blobs, :storage_type, :string
  end
end
