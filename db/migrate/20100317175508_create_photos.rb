class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|

      t.column :image_file_name,    :string
      t.column :image_content_type, :string
      t.column :image_file_size,    :integer
      t.column :image_updated_at,   :datetime

      t.timestamps
    end
  end

  def self.down
    drop_table :photos
  end
end
