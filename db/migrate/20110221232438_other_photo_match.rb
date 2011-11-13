class OtherPhotoMatch < ActiveRecord::Migration
  def self.up
    change_table :photo_pairs do |t|
      t.datetime :other_photo_match_revealed_at
    end
    add_index :photo_pairs, :other_photo_match_revealed_at
  end

  def self.down
    remove_column :photo_pairs, :other_photo_match_revealed_at
  end
end
