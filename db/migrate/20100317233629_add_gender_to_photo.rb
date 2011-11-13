class AddGenderToPhoto < ActiveRecord::Migration
  def self.up
    add_column :photos, :gender, :string, :length => 1
  end

  def self.down
    remove_column :photos, :gender
  end
end
