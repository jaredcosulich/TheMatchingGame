class AddInactivatedAt < ActiveRecord::Migration
  def self.up
    add_column :combos, :inactivated_at, :datetime
    execute "update combos set inactivated_at = created_at + interval '1 week' where active = false;"
  end

  def self.down
    remove_column :combos, :inactivated_at
  end
end
