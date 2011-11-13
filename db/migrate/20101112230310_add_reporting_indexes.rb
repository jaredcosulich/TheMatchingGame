class AddReportingIndexes < ActiveRecord::Migration
  def self.up
    add_index :games, :created_at
  end

  def self.down
    remove_index :games, :created_at
  end
end
