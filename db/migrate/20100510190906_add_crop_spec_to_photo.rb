class AddCropSpecToPhoto < ActiveRecord::Migration
  def self.up
    create_table :crops do |c|
      c.integer :photo_id
      c.integer :x
      c.integer :y
      c.integer :w
      c.integer :h
    end
  end

  def self.down
    drop_table :crops
  end
end
