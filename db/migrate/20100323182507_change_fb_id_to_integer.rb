class ChangeFbIdToInteger < ActiveRecord::Migration
  def self.up
    remove_column(:users, :fb_id)
    add_column(:users, :fb_id, :integer, :limit => 8)
  end

  def self.down
    remove_column(:users, :fb_id)
    add_column(:users, :fb_id, :string)
  end
end
