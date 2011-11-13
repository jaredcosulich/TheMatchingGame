class AddActivityAdjustmentToPhoto < ActiveRecord::Migration
  def self.up
    add_column :photos, :activity_adjustment, :integer, :default => 0
    update("update photos set activity_adjustment = 0")
  end

  def self.down
    remove_column :photos, :activity_adjustment
  end
end
