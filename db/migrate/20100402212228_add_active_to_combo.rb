class AddActiveToCombo < ActiveRecord::Migration
  def self.up
    add_column :combos, :active, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :combos, :active
  end
end
