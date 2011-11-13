class AddRejectedPhotos < ActiveRecord::Migration
  def self.up
    add_column(:photos, :rejected, :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column(:photos, :rejected)
  end
end
