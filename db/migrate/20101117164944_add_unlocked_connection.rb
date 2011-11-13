class AddUnlockedConnection < ActiveRecord::Migration
  def self.up
    add_column :responses, :photo_one_unlocked, :boolean, :default => false
    add_column :responses, :photo_two_unlocked, :boolean, :default => false
  end

  def self.down
    remove_column :responses, :photo_one_unlocked
    remove_column :responses, :photo_two_unlocked
  end
end
