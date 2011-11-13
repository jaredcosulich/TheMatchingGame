class AddReferrralIndex < ActiveRecord::Migration
  def self.up
    add_index :referrals, :player_id
  end

  def self.down
    remove_index :referrals, :player_id
  end
end
