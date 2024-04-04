class CreateBlobs < ActiveRecord::Migration[7.1]
  def change
    create_table :blobs, id: :string do |t|
      t.text :data

      t.timestamps
    end
  end
end
