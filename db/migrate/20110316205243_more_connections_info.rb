class MoreConnectionsInfo < ActiveRecord::Migration
  def self.up
    change_table :responses do |t|
      t.datetime :photo_one_archived_at
      t.datetime :photo_two_archived_at
    end
  end

  def self.down
    change_table :responses do |t|
      t.remove :photo_one_archived_at
      t.remove :photo_two_archived_at
    end
  end
end
