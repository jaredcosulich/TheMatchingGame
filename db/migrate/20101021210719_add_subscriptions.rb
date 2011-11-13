class AddSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :users, :subscribed_until, :datetime
  end

  def self.down
    remove_column :users, :subscribed_until
  end
end
