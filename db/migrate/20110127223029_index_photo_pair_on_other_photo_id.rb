class IndexPhotoPairOnOtherPhotoId < ActiveRecord::Migration
  def self.up
    add_index :photo_pairs, :other_photo_id
  end

  def self.down
    remove_index :photo_pairs, :other_photo_id
  end
end
