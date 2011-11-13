class IndexInterestsOnPlayerId < ActiveRecord::Migration
  def self.up
    add_index :interests, :player_id
  end

  def self.down
    remove_index :interests, :player_id
  end
end
