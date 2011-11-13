class AddPhotoProcessing < ActiveRecord::Migration
  def self.up
    add_column :photos, :image_processing, :boolean
  end

  def self.down
    remove_column :photos, :image_processing
  end
end
