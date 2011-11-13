class AddResponseReminderTracking < ActiveRecord::Migration
  def self.up
    add_column :combos, :photo_one_emailed_at, :timestamp
    add_column :combos, :photo_two_emailed_at, :timestamp
  end

  def self.down
    remove_column :combos, :photo_one_emailed_at
    remove_column :combos, :photo_two_emailed_at
  end
end
