class CreateFlickrPhotos < ActiveRecord::Migration
  def self.up
    create_table :flickr_photos do |t|
      t.string :flickr_url
      t.integer :photo_id

      t.timestamps
    end
  end

  def self.down
    drop_table :flickr_photos
  end
end
