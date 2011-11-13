class AddPhotoBuckets < ActiveRecord::Migration
  def self.up
    add_column :photos, :bucket, :integer
  end

  def self.down
    remove_column :photos, :bucket
  end
end
