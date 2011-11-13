class AddTimestamps < ActiveRecord::Migration
  @tables = [:combos, :players, :real_life_combos, :responses]
  def self.up
    @tables.each do |table_name|
      change_table table_name do |t|
        t.timestamps
      end
      update("update #{table_name} set created_at = now() where created_at is null")
      update("update #{table_name} set updated_at = created_at where updated_at is null")
    end
  end

  def self.down
    @tables.each do |table_name|
      change_table table_name do |t|
        t.remove_timestamps
      end
    end
  end
end
