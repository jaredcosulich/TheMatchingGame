class AddRotationToCrop < ActiveRecord::Migration
  def self.up
    add_column :crops, :rotation, :integer, :default => 0
  end

  def self.down
    remove_column :crops, :rotation
  end
end
